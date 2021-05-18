import flywheel
import datetime

# Initialize gear stuff
now = datetime.datetime.now().strftime("%y/%m/%d_%H:%M")
fw = flywheel.Client()
proj = fw.projects.find_first('label=AGTC')
subjects = proj.subjects()
analyses = fw.get_analyses('projects', proj.id, 'sessions')
struct = [ana for ana in analyses if ana.label.startswith('hcp-struct')]
func = [ana for ana in analyses if ana.label.startswith('hcp-func')]
sessions_that_have_func = []
for f in func:
    sessions_that_have_func.append(f.parent.id)
qp = fw.lookup('gears/hcp-icafix/0.2.0')
analysis_label = 'hcp-icafix %s' % qp.gear.version

for subject in subjects:
    subject_id = subject.label
    config = {'FIXClassifier': 'HCP_hp2000', 'HighPassFilter': 2000, 'PreserveOnError': True,
              'RegName': 'FS', 'Subject': subject_id}
    if subject_id != 'HEROgka1':
        sessions = subject.sessions()
        for session in sessions:
            if session.id in sessions_that_have_func:
                for f in func:
                    if subject.id == f.parents.subject and 'pRF_AP_run1' in f.label:
                        prf_run1 = f
                        prf_run1 = prf_run1.get_file('%s_pRF_AP_run1_hcpfunc.zip' % subject_id)
                    if subject.id == f.parents.subject and 'pRF_PA_run2' in f.label:
                        prf_run2 = f
                        prf_run2 = prf_run2.get_file('%s_pRF_PA_run2_hcpfunc.zip' % subject_id)
                    if subject.id == f.parents.subject and 'ventLocalizerA_AP_run1' in f.label:                        
                        ventral_a = f
                        ventral_a = ventral_a.get_file('%s_ventLocalizerA_AP_run1_hcpfunc.zip' % subject_id)
                    if subject.id == f.parents.subject and 'ventLocalizerB_PA_run1' in f.label:                        
                        ventral_b = f
                        ventral_b = ventral_b.get_file('%s_ventLocalizerB_PA_run1_hcpfunc.zip' % subject_id)
                for st in struct:
                    if subject.id == st.parents.subject:
                        struct_gear = st
                        struct_result = struct_gear.get_file(subject_id + '_hcpstruct.zip')
                
                if 'Left' in session.label:
                    which_eye = 'Left'
                else:
                    which_eye = 'Right'
                
                inputs = {'StructZip': struct_result, 'FuncZip': prf_run1, 'FuncZip2': prf_run2}
                new_analysis_label = analysis_label + ' [%s_%sEye_pRF]' % (subject_id, which_eye) + ' ' + now
                _id = qp.run(analysis_label=new_analysis_label, config=config, 
                inputs=inputs, destination=session)
                
                inputs = {'StructZip': struct_result, 'FuncZip': ventral_a, 'FuncZip2': ventral_b}
                new_analysis_label = analysis_label + ' [%s_%sEye_ventralLocalizer]' % (subject_id, which_eye) + ' ' + now
                _id = qp.run(analysis_label=new_analysis_label, config=config, 
                inputs=inputs, destination=session)   