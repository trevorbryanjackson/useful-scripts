import os
import slicer

def load_dicoms(subject_id, base_path, epoch):
    subject_path = base_path

    # Check if the subject folder exists
    if not os.path.exists(subject_path):
        print("Subject folder {subject_id} EPOCH {epoch} not found.".format(subject_id = subject_id, epoch = epoch))
        return

    # List all subdirectories in the subject folder
    subdirectories = [d for d in os.listdir(subject_path) if os.path.isdir(os.path.join(subject_path, d))]

    # Filter out folders containing "PHYSLOG"
    subdirectories = [d for d in subdirectories if "PHYSLOG" not in d]

    # Load DICOM files from each subdirectory
    slicer.util.selectModule("DICOM")
    dicomBrowser = slicer.modules.DICOMWidget.browserWidget.dicomBrowser

    for subdir in subdirectories:
        dicom_path = os.path.join(subject_path, subdir)
        print("Loading DICOMs from: {dicom_path}".format(dicom_path = dicom_path))
        dicomBrowser.importDirectory(dicom_path, dicomBrowser.ImportDirectoryAddLink)
        dicomBrowser.waitForImportFinished()
        #slicer.util.loadDicom(dicom_path)

if __name__ == "__main__":
    # Prompt the user for a subject ID
    
    # Specify the arbitrary base path
    while True:
        # Prompt the user for a subject ID
        project = input("Enter project (MAP/TAP; or 'exit' to quit): ").strip()
        if project.lower() == 'exit':
            print("Exiting the script.")
            break
        subject_id = input("Enter subject ID: ").strip()
        epoch = input("Enter Epoch number: ").strip()

        # Call the function to load DICOMs
        base_path = "/fs0/{p}/RAW/{s}/Brain/EPOCH{e}".format(p=project, s=subject_id, e=epoch)
        load_dicoms(subject_id, base_path, epoch)