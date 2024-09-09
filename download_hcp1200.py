import os
import boto3
from botocore.exceptions import NoCredentialsError
from concurrent.futures import ThreadPoolExecutor, as_completed
from functools import partial

def check_image_types_present(s3, bucket_name, subject, base_path, image_types):
    """
    Check if all specified image types are present for the subject.
    
    Parameters:
    s3 (boto3.client): The S3 client.
    bucket_name (str): The S3 bucket name.
    subject (str): The subject ID.
    base_path (str): The base path to search in.
    image_types (list): A list of image types to check (e.g., rfMRI, tfMRI, T1w, etc.).

    Returns:
    bool: True if all image types are present, False otherwise.
    """
    result = s3.list_objects_v2(Bucket=bucket_name, Prefix=base_path.format(subject=subject))

    if 'Contents' in result:
        found_image_types = set()

        for obj in result['Contents']:
            file_key = obj['Key']
            for image_type in image_types:
                if image_type in file_key:
                    found_image_types.add(image_type)

        # Check if all requested image types are present
        missing_types = set(image_types) - found_image_types
        if missing_types:
            print(f"Error: Subject {subject} is missing the following image types: {', '.join(missing_types)}")
            return False
        return True
    else:
        print(f"No data found for subject {subject} at {base_path.format(subject=subject)}")
        return False

def check_data_completeness(subject_dir, image_types):
    """
    Check that all required files are present in the subject directory.
    
    Parameters:
    subject_dir (str): The directory where the subject's data is saved.
    image_types (list): A list of image types to check.
    
    Returns:
    bool: True if all required files are present, False otherwise.
    """
    expected_files = {
        'rfMRI_REST1': 2,
        'rfMRI_REST2': 2,
        'tfMRI': 2  # Assuming 1 left and 1 right image per task-based scan
    }
    
    files = os.listdir(subject_dir)
    found_files = {key: 0 for key in expected_files.keys()}

    for file in files:
        for key in expected_files.keys():
            if key in file:
                found_files[key] += 1

    for key, expected_count in expected_files.items():
        if found_files[key] != expected_count:
            print(f"Error: Subject directory {subject_dir} is missing {expected_count - found_files[key]} {key} images.")
            return False
    return True

def download_subject_data(subject_list, aws_access_key, aws_secret_key, save_dir, image_types, num_threads):
    """
    Download 3T imaging and behavioral data from the HCP 1200 Young Adult release.

    Parameters:
    subject_list (str): Path to the text file containing subject IDs.
    aws_access_key (str): AWS access key for HCP S3 access.
    aws_secret_key (str): AWS secret key for HCP S3 access.
    save_dir (str): Directory to save the downloaded data.
    image_types (list): A list of image types to download (e.g., BOLD, T1w, T2w, DTI, etc.).
    num_threads (int): Number of threads to use for parallel downloading.
    """
    # Load subjects
    with open(subject_list, 'r') as f:
        subjects = [line.strip() for line in f.readlines()]

    # Set up S3 connection
    s3 = boto3.client('s3', 
                      aws_access_key_id=aws_access_key, 
                      aws_secret_access_key=aws_secret_key,
                      region_name='us-west-2')

    bucket_name = 'hcp-openaccess'
    
    # Define the base paths for 3T imaging and behavioral data
    base_3T_path = 'HCP_1200/{subject}/unprocessed/3T/'
    behavioral_data_path = 'HCP_1200/{subject}/behavioral/'

    def process_subject(subject):
        print(f"Checking data for subject {subject}...")

        # Check if all image types are present for this subject
        if check_image_types_present(s3, bucket_name, subject, base_3T_path, image_types):
            print(f"Downloading data for subject {subject}...")

            # Define directories
            subject_dir = os.path.join(save_dir, subject)
            os.makedirs(subject_dir, exist_ok=True)

            # Download 3T imaging data for all image types
            try:
                for image_type in image_types:
                    imaging_prefix = base_3T_path.format(subject=subject)
                    download_from_s3(s3, bucket_name, imaging_prefix, subject_dir, image_type)

                # Download behavioral data
                behavioral_prefix = behavioral_data_path.format(subject=subject)
                download_from_s3(s3, bucket_name, behavioral_prefix, subject_dir)

                # Check data completeness
                if not check_data_completeness(subject_dir, image_types):
                    print(f"Incomplete data for subject {subject}.")
            except NoCredentialsError:
                print("Error: AWS credentials not found.")
                return
        else:
            print(f"Skipping subject {subject} due to missing image types.")

    # Parallel processing
    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        futures = [executor.submit(process_subject, subject) for subject in subjects]
        for future in as_completed(futures):
            try:
                future.result()
            except Exception as e:
                print(f"Error processing subject: {e}")

def download_from_s3(s3, bucket_name, prefix, subject_dir, image_type=None):
    """
    Download all files from the specified S3 prefix. Filters files by image type if specified.
    """
    result = s3.list_objects_v2(Bucket=bucket_name, Prefix=prefix)
    
    if 'Contents' in result:
        for obj in result['Contents']:
            file_key = obj['Key']
            file_name = os.path.basename(file_key)
            relative_path = os.path.relpath(file_key, start=prefix)
            
            # If an image type is specified, skip files that don't match
            if image_type and image_type not in file_key:
                continue

            # Create directories based on the relative path
            save_path = os.path.join(subject_dir, relative_path)
            os.makedirs(os.path.dirname(save_path), exist_ok=True)
            
            print(f"Downloading {file_key} to {save_path}...")
            s3.download_file(bucket_name, file_key, save_path)
    else:
        print(f"No data found for {prefix}")

if __name__ == "__main__":
    import argparse

    # Parse arguments
    parser = argparse.ArgumentParser(description="Download 3T imaging and behavioral data from HCP Young Adult 1200 release, check for multiple image types, and parallelize downloads.")
    parser.add_argument('--subject_list', required=True, help="Path to the subject list file.")
    parser.add_argument('--access_key', required=True, help="AWS access key for HCP S3.")
    parser.add_argument('--secret_key', required=True, help="AWS secret key for HCP S3.")
    parser.add_argument('--save_dir', required=True, help="Directory to save the downloaded data.")
    parser.add_argument('--image_types', nargs='+', required=True, help="List of image types to download (e.g., rfMRI, tfMRI, T1w, T2w, DTI).")
    parser.add_argument('--num_threads', type=int, default=4, help="Number of threads to use for parallel downloads.")

    args = parser.parse_args()

    # Download data, check completeness, and parallelize downloads
    download_subject_data(args.subject_list, args.access_key, args.secret_key, args.save_dir, args.image_types, args.num_threads)
