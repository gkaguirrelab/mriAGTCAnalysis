import flywheel
import datetime

# Initialize gear stuff
now = datetime.datetime.now().strftime("%y/%m/%d_%H:%M")
fw = flywheel.Client()
proj = fw.projects.find_first('label=AGTC_OL')
subjects = proj.subjects()
analyses = fw.get_analyses('projects', proj.id, 'sessions')
struct = [ana for ana in analyses if ana.label.startswith('hcp-struct')]
func = [ana for ana in analyses if ana.label.startswith('hcp-func')]
sessions_that_have_func = []
for f in func:
    sessions_that_have_func.append(f.parent.id)
qp = fw.lookup('gears/hcp-func/0.1.7')
analysis_label = 'hcp-func %s' % qp.gear.version

freesurfer_license = proj.get_file('freesurfer_license.txt')
coef_grad = proj.get_file('coeff.grad')


for subject in subjects:
    subject_id = subject.label
    if subject_id != 'HEROgka1':
        sessions = subject.sessions()
        for session in sessions:
            if session.id not in sessions_that_have_func:
                for st in struct:
                    if subject.id == st.parents.subject:
                        struct_gear = st
                        struct_result = struct_gear.get_file(subject_id + '_hcpstruct.zip')
                
                acquisition_list=[]
                acquisitions = session.acquisitions()
                for acquisition in acquisitions:
                    if acquisition.label == 'fmap_dir-AP_acq-SpinEchoFieldMap':
                        spin_echo_negative = acquisition             
                        spin_echo_negative = spin_echo_negative.files[1]
                    if acquisition.label == 'fmap_dir-PA_acq-SpinEchoFieldMap':
                        spin_echo_positive = acquisition
                        spin_echo_positive = spin_echo_positive.files[1]
                    
                inputs = {'FreeSurferLicense': freesurfer_license, 'GradientCoeff': coef_grad, 
                          'SpinEchoNegative': spin_echo_negative, 'SpinEchoPositive': spin_echo_positive,
                          'StructZip': struct_result}
     

                config = {'AnatomyRegDOF': 6, 'BiasCorrection': 'SEBased', 'MotionCorrection': 'MCFLIRT',
                          'RegName': 'FS', 'Subject': subject_id}
                    
                for acquisition in acquisitions:
                    if 'func_task' in acquisition.label and 'SBRef' not in acquisition.label and 'PhysioLog' not in acquisition.label:
                        acq = acquisition 
                        label = acquisition.label
                        for i in acq.files:
                            if 'nii.gz' in i.name:
                                acquisition_to_run = i 
                        for ref in acquisitions:
                            if label + '_SBRef' == ref.label:
                                scout = ref.files[1]
                        inputs['fMRIScout'] = scout 
                        inputs['fMRITimeSeries'] = acquisition_to_run
                        config['fMRIName'] = label[10:]                   
                        new_analysis_label = analysis_label + ' ' + '[' + label[10:] + ']' + ' ' + now
                        _id = qp.run(analysis_label=new_analysis_label, config=config, 
                        inputs=inputs, destination=session)
    
                                                
