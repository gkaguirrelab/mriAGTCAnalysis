import flywheel
import datetime

# Initialize gear stuff
now = datetime.datetime.now().strftime("%y/%m/%d_%H:%M")
fw = flywheel.Client('upenn.flywheel.io:DTIiZcuXBVlpJmCLZt')
proj = fw.projects.find_first('label=AGTC')
subjects = proj.subjects()
analyses = fw.get_analyses('projects', proj.id, 'sessions')
struct = [ana for ana in analyses if ana.label.startswith('hcp-struct')]
qp = fw.lookup('gears/hcp-struct/0.1.8')
analysis_label = 'hcp-struct %s %s' % (qp.gear.version, now)
sessions_that_have_struct = []
for s in struct:
    sessions_that_have_struct.append(s.parent.id)
freesurfer_license = proj.get_file('freesurfer_license.txt')
config = {'RegName': 'FS',
          'Subject': 'NA'}

T1_name = 'anat-T1w_acq-axial'
T2_name = 'anat-T2w_acq-spc'
for subject in subjects:
    sessions = subject.sessions()
    for session in sessions:
        acquisition_list=[]
        acquisitions = session.acquisitions()
        for acquisition in acquisitions:
            acquisition_list.append(acquisition.label)
        if T1_name in acquisition_list and T2_name in acquisition_list and not session.id in sessions_that_have_struct:
            destination = session
            for acquisition in acquisitions:
                if 'DISCARDED' not in acquisition.label and T1_name in acquisition.label:
                    files = acquisition.files
                    for file in files:
                        if 'nii.gz' in file.name:
                            T1_image = file
                if 'DISCARDED' not in acquisition.label and T2_name in acquisition.label:
                    files = acquisition.files
                    for file in files:
                        if 'nii.gz' in file.name:
                            T2_image = file
            config['Subject'] = subject.label
            inputs = {'FreeSurferLicense': freesurfer_license, 'T1': T1_image, 'T2': T2_image}
            print('submitting HCP-struct for AGTC subjects')
            try:
                _id = qp.run(analysis_label=analysis_label,
                              config=config, inputs=inputs, destination=destination)
            except Exception as e:
                print(e)