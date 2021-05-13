import getpass, os, platform, flywheel

'''
This script upload AGTC videos to their respective MRI acquisitions on Flywheel
Do not forget to set variables below to find the videos
''' 

# Set some variables
subject_id = 'MEE2208'
recording_date = '2021-05-12'
session_name = 'Session1Right'
flywheel_session_name = 'Hadassah_RightEyeStim'
workdir = '/Users/iron/Desktop/work'

# Make the workdir in case a folder is specified 
if not os.path.exists(workdir):
    os.system('mkdir -p %s' % workdir)

# Initialize Flywheel 
fw = flywheel.Client('upenn.flywheel.io:8P7zdNhXBWiahwEGKt')

# Get flywheel subject, session
proj = fw.projects.find_first('label=AGTC')
for ses in proj.sessions():
    if ses.label == flywheel_session_name:
        session = ses

# Get the list of acquisitions in the flywheel 
acquisitions = {}
for acq in session.acquisitions():
    acquisitions[acq.label] = acq

# Get the username
user_name = getpass.getuser()

# Get the OS
os_type = platform.system()

# Get the paths 
if os_type == 'Windows': 
    folder_path = 'C:\\Users\\{user_name}\\Dropbox (Aguirre-Brainard Lab)\\AGTC_data\\Videos\\HadassahFMRI'.format(user_name = user_name)
elif os_type == 'Darwin':
    folder_path = '/Users/{user_name}/Dropbox (Aguirre-Brainard Lab)/AGTC_data/Videos/HadassahFMRI'.format(user_name = user_name)
elif os_type == 'Linux':
    folder_path = '/home/{user_name}/Dropbox (Aguirre-Brainard Lab)/AGTC_data/Videos/HadassahFMRI'.format(user_name = user_name)
else:
    raise RuntimeError('The operating system is not recognized')
    
# Construct video folder and make one in the workdir 
video_path = os.path.join(folder_path,subject_id,recording_date,session_name)
workdir_video_path = os.path.join(workdir,subject_id,recording_date,session_name)
if not os.path.exists(workdir_video_path):
    os.system('mkdir {workdir_video_path}'.format(workdir_video_path=workdir_video_path))

# Loop through each image, get the name, increase the brightness and upload to Flywheel 
for vid_name in os.listdir(video_path):
    vid_full_path = os.path.join(video_path, vid_name)
    save_path = os.path.join(workdir_video_path, vid_name)
    command = 'ffmpeg -i \"{vid_full_path}\" -vcodec h264 -c:a copy -pix_fmt yuv420p -vf eq=brightness=0.5:contrast=2 \"{save_path}\"'.format(vid_full_path=vid_full_path, save_path=save_path)
    os.system(command)

# Upload stuff to Flywheel 
print('Upload videos to Flywheel')
for vid in os.listdir(workdir_video_path):
    if vid[:-4] in acquisitions.keys():
        acquisitions[vid[:-4]].upload_file(os.path.join(workdir_video_path, vid))
