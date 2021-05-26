import flywheel
import datetime

# Initialize gear stuff
now = datetime.datetime.now().strftime("%y/%m/%d_%H:%M")
fw = flywheel.Client('upenn.flywheel.io:DTIiZcuXBVlpJmCLZt')
proj = fw.projects.find_first('label=AGTC')
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
                
                print(session.label)
                acquisition_list=[]
                acquisitions = session.acquisitions()
                for acquisition in acquisitions:
                    if acquisition.label == 'fmap_dir-AP_acq-SpinEchoFieldMap':
                        spin_echo_negative = acquisition             
                        spin_echo_negative = spin_echo_negative.files[1]
                    if acquisition.label == 'fmap_dir-PA_acq-SpinEchoFieldMap':
                        spin_echo_positive = acquisition
                        spin_echo_positive = spin_echo_positive.files[1]
                    if acquisition.label == 'func_task-prf_acq-PA_run-02_SBRef':
                        fmri_scout = acquisition
                        fmri_scout = fmri_scout.files[1]
                    
                inputs = {'FreeSurferLicense': freesurfer_license, 'GradientCoeff': coef_grad, 
                          'SpinEchoNegative': spin_echo_negative, 'SpinEchoPositive': spin_echo_positive,
                          'StructZip': struct_result}
     

                config = {'AnatomyRegDOF': 6, 'BiasCorrection': 'SEBased', 'MotionCorrection': 'MCFLIRT',
                          'RegName': 'FS', 'Subject': subject_id}
                    
                for acquisition in acquisitions:
                    if acquisition.label == 'func_task-prf_acq-AP_run-01':  
                        prf_01 = acquisition 
                        for i in prf_01.files:
                            if 'nii.gz' in i.name:
                                prf_01 = i
                        for ref in acquisitions:
                            if ref.label == acquisition.label + '_SBRef':
                                scout = ref
                                scout = ref.files[1]
                        inputs['fMRIScout'] = scout 
                        inputs['fMRITimeSeries'] = prf_01
                        config['fMRIName'] = 'pRF_AP_run1'
                        new_analysis_label = analysis_label + ' [pRF_AP_run1]' + ' ' + now
                        _id = qp.run(analysis_label=new_analysis_label, config=config, 
                        inputs=inputs, destination=session)
                        
                    elif acquisition.label == 'func_task-prf_acq-PA_run-02':
                        prf_02 = acquisition 
                        for i in prf_02.files:
                            if 'nii.gz' in i.name:
                                prf_02 = i
                        for ref in acquisitions:
                            if ref.label == acquisition.label + '_SBRef':
                                scout = ref
                                scout = ref.files[1]
                        inputs['fMRIScout'] = scout                         
                        inputs['fMRITimeSeries'] = prf_02
                        config['fMRIName'] = 'pRF_PA_run2'
                        new_analysis_label = analysis_label + ' [pRF_PA_run2]' + ' ' + now
                        _id = qp.run(analysis_label=new_analysis_label, config=config, 
                        inputs=inputs, destination=session)
                                                    
                    elif acquisition.label == 'func_task-ventralLocalizerA_acq-AP_run01':
                        ventral_a = acquisition  
                        for i in ventral_a.files:
                            if 'nii.gz' in i.name:
                                ventral_a = i
                        for ref in acquisitions:
                            if ref.label == acquisition.label + '_SBRef':
                                scout = ref
                                scout = ref.files[1]
                        inputs['fMRIScout'] = scout                                 
                        inputs['fMRITimeSeries'] = ventral_a
                        config['fMRIName'] = 'ventLocalizerA_AP_run1'
                        new_analysis_label = analysis_label + ' [ventLocalizerA_AP_run1]' + ' ' + now
                        _id = qp.run(analysis_label=new_analysis_label, config=config, 
                        inputs=inputs, destination=session)
                                                    
                    elif acquisition.label == 'func_task-ventralLocalizerB_acq-PA_run01':
                        ventral_b = acquisition  
                        for i in ventral_b.files:
                            if 'nii.gz' in i.name:
                                ventral_b = i
                        for ref in acquisitions:
                            if ref.label == acquisition.label + '_SBRef':
                                scout = ref
                                scout = ref.files[1]
                        inputs['fMRIScout'] = scout                                 
                        inputs['fMRITimeSeries'] = ventral_b
                        config['fMRIName'] = 'ventLocalizerB_PA_run1'
                        new_analysis_label = analysis_label + ' [ventLocalizerB_PA_run1]' + ' ' + now
                        _id = qp.run(analysis_label=new_analysis_label, config=config, 
                        inputs=inputs, destination=session)
                                                