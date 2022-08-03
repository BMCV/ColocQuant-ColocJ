"""this program opens a gui that ask the user to enter necessary input for detection and colocalization and then executes detection and colocalization"""
import os
import configparser
import pandas as pd
from datetime import date
from shutil import copyfile
import tkinter
import tkinter.filedialog
import tkinter.messagebox
from tkinter import StringVar
from tkinter import OptionMenu
from skimage import io
import sys
import re
import platform
# changes sigma & threshold in .cfg file dependant on input
# creates detection directories for that


def files_present():
    missing = False
    missing_string = ""
    file_list = [detfile, cfgtemp, cur_dir+os.sep+"colocalization.py", cur_dir+os.sep+"csv2points.py", cur_dir+os.sep+"csv2mdf_intens_area.pl"]
    for file in file_list:
        if not os.path.isfile(file):
            missing_string = missing_string + os.path.basename(file)+" "
            missing = True
    if missing:   
        root = tkinter.Tk()
        root.iconify()
        root.title('Files Missing')
        tkinter.messagebox.showwarning('Warning', 'The following files are missing: \n' + missing_string + '\nThe necessary files need to be in same directory as the executed Python file.') 
        root.destroy()
        sys.exit()


def create_memory():
    config2 = configparser.ConfigParser()
    config2.optionxform = str
    config2['VALUES'] = {'sigma1': '3', 'sigma2': '3', 'sigma3': '3', 'threshold1': '3', 'threshold2': '3', 'threshold3': '3', 'D12': '5', 'D13': '5', 'D23': '5'}
    config2['PATHS'] = {'input_ch1': '', 'input_ch2': '', 'input_ch3': '', 'output_dir': ''}
    with open(cur_dir+os.sep+'memory.cfg', 'w+') as configfile:
        config2.write(configfile)


def update_memory(sigma, threshold, d12, d13, d23):
    config2 = configparser.ConfigParser()
    config2.optionxform = str  # makes the parser casesensitive so it doesn't just write lowercase
    cfg_dir = cur_dir+os.sep+'memory.cfg'
    with open(cfg_dir) as f:
        config2.read_file(f)
    if not os.path.isfile(cfg_dir):
        create_memory()
    else:
        config2.set('VALUES', 'sigma1', value=sigma[0])
        config2.set('VALUES', 'sigma2', value=sigma[1])
        config2.set('VALUES', 'sigma3', value=sigma[2])
        config2.set('VALUES', 'threshold1', value=threshold[0])  
        config2.set('VALUES', 'threshold2', value=threshold[1])
        config2.set('VALUES', 'threshold3', value=threshold[2])
        config2.set('VALUES', 'D12', value=d12)
        config2.set('VALUES', 'D13', value=d13)
        config2.set('VALUES', 'D23', value=d23)
        config2.set('PATHS', 'input_ch1', value=input_list[0])
        config2.set('PATHS', 'input_ch2', value=input_list[1])
        config2.set('PATHS', 'input_ch3', value=input_list[2])
        config2.set('PATHS', 'output_dir', value=chosen_dir)

        with open(cfg_dir, 'w+') as configfile:
            config2.write(configfile, space_around_delimiters=False)


def run_gui():
    # asks for output directory
    global chosen_dir, double_triple
    def output_dir():
        global chosen_dir
        chosen_dir = tkinter.filedialog.askdirectory(
            parent=root, initialdir='C:/', title='Choose directory')
        # old code: chosen_dir = chosen_dir.replace('/', '\\')  # directory path is created with forward slashes, those need to be replaced
        entry29.delete(0, 23)
        if len(chosen_dir) > 17:
            entry29.insert(0, "..."+chosen_dir[-17:])
        else:
            entry29.insert(0, chosen_dir)
    # ask for input .tif files

    def input_file(channel):
        global input_list, init_dir, composite_input
        if channel == 3:
            entry22_5["state"] = "normal"
            entry24.delete(0,23)
            entry25.delete(0,23)
            entry26.delete(0,23)
            entry24["state"] = "disabled"    
            entry25["state"] = "disabled"
            entry26["state"] = "disabled"
            composite_input = True
        else:
            composite_input = False
            if entry22_5["state"] == "normal":#tests if composite input was chosen before
                input_list = ["","",""]#resets input list, if composite was active before
                entry24.delete(0,23)
                entry25.delete(0,23)
                entry26.delete(0,23)
            entry22_5["state"] = "disabled"
            entry24["state"] = "normal"
            if tickbox_var.get() != "Detection":
                entry25["state"] = "normal"
                if tickbox_var.get() != "Double Colocalization":
                    entry26["state"] = "normal"
        
        entry = [entry24, entry25, entry26, entry22_5]
        chosen_input = tkinter.filedialog.askopenfilename(
            parent=root, initialdir=init_dir, title='Choose .tif file')

        if not chosen_input == "" and not chosen_input.endswith(".tif"):
            tkinter.messagebox.showwarning("Warning", 'Please select only .tif files.')
            return
        #chosen_input = chosen_input.replace('/', '\\')  # directory path is created with forward slashes, those need to be replaced
        entry[channel].delete(0, 23)
        if len(chosen_input) > 20:
            entry[channel].insert(0, "..."+chosen_input[-20:])
        else:
            entry[channel].insert(0, chosen_input)
        if channel == 3:
            com_return = split_composite(chosen_input, chosen_input)
            if com_return == False:
                entry[channel].delete(0, 23)
                input_list = ["", "", ""]
                
        else:
            input_list[channel] = chosen_input #sets input_list[3] to composite, if composite chosen
            init_dir = os.path.dirname(chosen_input)
    
    def split_composite(input_composite, chosen_input):
        global input_list, init_dir, red, green, blue, double_triple
        if input_composite =="":
            return False
        composite = io.imread(input_composite)
        if composite.dtype != "uint16":
            tkinter.messagebox.showwarning("Warning", "Please only use 16-bit images")
            return False
        if len(composite.shape) == 2:
            tkinter.messagebox.showwarning("Warning", "Please only use two- or three-channel images")
            return False
        if composite.shape[-1] != 3 and composite.shape[-3] != 2:
            tkinter.messagebox.showwarning("Warning", "Please only use two- or three-channel images")
            return False
        if len(composite.shape) == 3: #image with one slice
            if composite.shape[2] == 3: #three-channel image
                red = composite[:,:,0]
                green = composite[:,:,1]
                blue = composite[:,:,2]
                input_list = ["{}/channel_1.tif".format(chosen_dir),"{}/channel_2.tif".format(chosen_dir),"{}/channel_3.tif".format(chosen_dir)]
            elif composite.shape[0] == 2: #two-channel image
                if "Triple" in double_triple:#only 3-channel images for 3-channel mode
                    tkinter.messagebox.showwarning("Warning", "Please use a three-channel image for this mode")
                    return False
                red = composite[0,:,:]
                green = composite[1,:,:]
                input_list = ["{}/channel_1.tif".format(chosen_dir),"{}/channel_2.tif".format(chosen_dir),""]
        else:
            if composite.shape[3] == 3: #three-channel image
                red = composite[:,:,:,0]
                green = composite[:,:,:,1]
                blue = composite[:,:,:,2]
                input_list = ["{}/channel_1.tif".format(chosen_dir),"{}/channel_2.tif".format(chosen_dir),"{}/channel_3.tif".format(chosen_dir)]
            elif composite.shape[1] == 2: #two-channel image
                if "Triple" in double_triple:#only 3-channel images for 3-channel mode
                    tkinter.messagebox.showwarning("Warning", "Please use a three-channel image for this mode")
                    return False
                red = composite[:,0,:,:]
                green = composite[:,1,:,:]
                input_list = ["{}/channel_1.tif".format(chosen_dir),"{}/channel_2.tif".format(chosen_dir),""]
        init_dir = os.path.dirname(chosen_input)
        return True
        
    def double_or_triple():
        global composite_input, double_triple
        selected_option = tickbox_var.get()
        double_triple = selected_option
        if (selected_option == "Triple Colocalization") or (selected_option == "Triple and Double (Ch1, Ch2)") or (selected_option == "Triple and Double (Ch1, Ch3)") or (selected_option == "Triple and Double (Ch2, Ch3)"): 
            entry15["state"] = "normal"
            entry16["state"] = "normal"
            entry18["state"] = "normal"
            entry19["state"] = "normal"
            entry20["state"] = "normal"
            entry21["state"] = "normal"
            entry22["state"] = "normal"
            entry22_5["state"] = "normal"
            button10_5["state"] = "normal"
            button11["state"] = "normal"
            button12["state"] = "normal"
            button13["state"] ="normal"
            if composite_input == False:
                entry24["state"] = "normal"
                entry25["state"] = "normal"
                entry26["state"] = "normal"
                entry22_5["state"] = "disabled"
        elif (selected_option == "Double Colocalization"):
            # everything activated
            entry15["state"] = "normal"
            entry16["state"] = "normal"
            entry18["state"] = "normal"
            entry19["state"] = "normal"
            entry20["state"] = "normal"
            entry21["state"] = "normal"
            entry22["state"] = "normal"
            entry24["state"] = "normal"
            entry25["state"] = "normal"
            entry26["state"] = "normal"
            button11["state"] = "normal"
            button12["state"] = "normal"
            # then the specific limitations
            entry15["state"] = "normal"
            entry18["state"] = "normal"
            entry20["state"] = "normal"
            entry16["state"] = "disabled"
            entry19["state"] = "disabled"
            entry21["state"] = "disabled"
            entry22["state"] = "disabled"
            entry24["state"] = "disabled"
            entry25["state"] = "disabled"
            entry26["state"] = "disabled"
            entry22_5["state"] = "normal"
            button10_5["state"] = "normal"
            button13["state"] ="disabled"
            if composite_input == False:
                entry24["state"] = "normal"
                entry25["state"] = "normal"
                entry22_5["state"] = "disabled"

        elif (selected_option == "Detection"):
            composite_input = False
            # everything activated
            entry15["state"] = "normal"
            entry16["state"] = "normal"
            entry18["state"] = "normal"
            entry19["state"] = "normal"
            entry20["state"] = "normal"
            entry21["state"] = "normal"
            entry22["state"] = "normal"
            entry24["state"] = "normal"
            entry25["state"] = "normal"
            entry26["state"] = "normal"
            # then the specific limitations
            entry15["state"] = "disabled"
            entry16["state"] = "disabled"
            entry18["state"] = "disabled"
            entry19["state"] = "disabled"
            entry20["state"] = "disabled"
            entry21["state"] = "disabled"
            entry22["state"] = "disabled"
            entry25["state"] = "disabled"
            entry26["state"] = "disabled"
            entry22_5["state"] = "disabled"
            button10_5["state"] = "disabled"
            button12["state"] = "disabled"
            button13["state"] ="disabled"
    def read_input():
        # sets global variables to choosen values
        global sigma, threshold, d12, d13, d23, folder_name, main_dir, chosen_dir, double_triple, red, green, blue, input_list
        if chosen_dir == "":
            tkinter.messagebox.showwarning("Warning", "No output directory has been chosen.")
            return
        sigma1 = entry14.get()
        sigma2 = entry15.get()
        sigma3 = entry16.get()
        threshold1 = entry17.get()
        threshold2 = entry18.get()
        threshold3 = entry19.get()
        d12 = entry20.get()
        d13 = entry21.get()
        d23 = entry22.get()
        folder_name = entry23.get()
        sigma = [sigma1, sigma2, sigma3]
        threshold = [threshold1, threshold2, threshold3]
        main_dir = chosen_dir+os.sep+folder_name
        
        #catching wrong entries
        x = re.findall("[ ]", main_dir)
        if len(x) > 0:
            tkinter.messagebox.showwarning("Warning", 'Please choose an directory that does not have an empty space in its name.')
            return
        # checking if a input .tif file has been choosen for each channel
        for i in range(0,3) :
            if double_triple == "Detection" and i > 0: break 
            if double_triple == "Double Colocalization" and i > 1: break 
            if  input_list[i] == "":
                tkinter.messagebox.showwarning("Warning", "Please select an input file for each channel.")
                return
        # checking if target folder already exits
        # if a folder has been chosen; folder already exists
        # necessary values entered as float/int
        x = re.findall("["+re.escape('*<>/\|]"?')+"]", folder_name)
        if len(x) > 0:
            tkinter.messagebox.showwarning("Warning", 'Directory name is not allowed to contain following characters: "|][/\*?<>')
            return
        if folder_name == "":
            tkinter.messagebox.showwarning("Warning", "Please select a name for the target directory.")
            return
        else:
            if os.path.exists(main_dir):
                tkinter.messagebox.showwarning("Warning", "The chosen directory already exists. Please choose a different directory path or name.")
                return
        if is_float([sigma1, sigma2, sigma3, threshold1, threshold2, threshold3, d12, d13, d23]) is False:
            tkinter.messagebox.showwarning("Warning", "The values have not been entered correctly.")
        else:
            if composite_input == True:#only change input list here when composite used as input
                if double_triple == "Double Colocalization":
                    input_list = ["{}/channel_1.tif".format(main_dir),"{}/channel_2.tif".format(main_dir),""]
                elif "Triple" in double_triple:
                    input_list = ["{}/channel_1.tif".format(main_dir),"{}/channel_2.tif".format(main_dir),"{}/channel_3.tif".format(main_dir)]    
            update_memory(sigma, threshold, d12, d13, d23)
            root.destroy()

    def is_float(list):
        for s in list:
            try:
                float(s)
            except ValueError:
                return False

    root = tkinter.Tk()
    root.title('ColocQuant BMCV Group')
    
    tickbox_var = StringVar(root) # varible for selected option
    tickbox_var.set("Triple Colocalization") # default




    label1 = tkinter.Label(root, text="Filter Size \u03C3 (Ch1)", relief=tkinter.GROOVE, padx=8, pady=8, bg="#ffebe6")
    label2 = tkinter.Label(root, text="Filter Size \u03C3 (Ch2)", relief=tkinter.GROOVE, padx=8, pady=8, bg="#e6ffe6")
    label3 = tkinter.Label(root, text="Filter Size \u03C3 (Ch3)", relief=tkinter.GROOVE, padx=8, pady=8, bg="#e6faff")
    label4 = tkinter.Label(root, text="Detection Threshold (Ch1)", relief=tkinter.GROOVE, padx=8, pady=8, bg="#ffebe6")
    label5 = tkinter.Label(root, text="Detection Threshold (Ch2)", relief=tkinter.GROOVE, padx=8, pady=8, bg="#e6ffe6")
    label6 = tkinter.Label(root, text="Detection Threshold (Ch3)", relief=tkinter.GROOVE, padx=8, pady=8, bg="#e6faff")
    label7 = tkinter.Label(root, text="Dmax (Ch1, Ch2)", relief=tkinter.GROOVE, padx=8, pady=8)
    label8 = tkinter.Label(root, text="Dmax (Ch1, Ch3)", relief=tkinter.GROOVE, padx=8, pady=8)
    label9 = tkinter.Label(root, text="Dmax (Ch2, Ch3)", relief=tkinter.GROOVE, padx=8, pady=8)
    label10 = tkinter.Label(root, text="Directory Name", relief=tkinter.GROOVE, padx=8, pady=8)
    button10_5 = tkinter.Button(root, text="Input (composite)", command=lambda: input_file(3), relief=tkinter.GROOVE, padx=8, pady=8)
    button11 = tkinter.Button(root, text="Input (Ch1)", command=lambda: input_file(0), relief=tkinter.GROOVE, padx=8, pady=8, bg="#ffebe6")
    button12 = tkinter.Button(root, text="Input (Ch2)", command=lambda: input_file(1), relief=tkinter.GROOVE, padx=8, pady=8, bg="#e6ffe6")
    button13 = tkinter.Button(root, text="Input (Ch3)", command=lambda: input_file(2), relief=tkinter.GROOVE, padx=8, pady=8, bg="#e6faff")
    entry14 = tkinter.Entry(root, relief=tkinter.GROOVE, justify = "center")
    entry15 = tkinter.Entry(root, relief=tkinter.GROOVE, justify = "center")
    entry16 = tkinter.Entry(root, relief=tkinter.GROOVE, justify = "center")
    entry17 = tkinter.Entry(root, relief=tkinter.GROOVE, justify = "center")
    entry18 = tkinter.Entry(root, relief=tkinter.GROOVE, justify = "center")
    entry19 = tkinter.Entry(root, relief=tkinter.GROOVE, justify = "center")
    entry20 = tkinter.Entry(root, relief=tkinter.GROOVE, justify = "center")
    entry21 = tkinter.Entry(root, relief=tkinter.GROOVE, justify = "center")
    entry22 = tkinter.Entry(root, relief=tkinter.GROOVE, justify = "center")
    entry22_5 = tkinter.Entry(root, relief=tkinter.GROOVE, justify = "center")
    entry23 = tkinter.Entry(root, relief=tkinter.GROOVE, justify = "center")
    entry24 = tkinter.Entry(root, relief=tkinter.GROOVE, justify = "center")
    entry25 = tkinter.Entry(root, relief=tkinter.GROOVE, justify = "center")
    entry26 = tkinter.Entry(root, relief=tkinter.GROOVE, justify = "center")
    button27 = tkinter.Button(root, text="Start", command=lambda: read_input(), relief=tkinter.GROOVE, padx=0, pady=0, font=40)
    button28 = tkinter.Button(root, text="Output Directory", command=lambda: output_dir(), relief=tkinter.GROOVE, padx=8, pady=8)
    entry29 = tkinter.Entry(root, relief=tkinter.GROOVE)
    tickbox30 = OptionMenu(root, tickbox_var, "Triple Colocalization", "Double Colocalization", "Triple and Double (Ch1, Ch2)", "Triple and Double (Ch1, Ch3)", "Triple and Double (Ch2, Ch3)", "Detection", command=lambda x: double_or_triple())

    label1.grid(column=0, row=0, sticky="nsew")
    label2.grid(column=0, row=1, sticky="nsew")
    label3.grid(column=0, row=2, sticky="nsew")
    label4.grid(column=0, row=3, sticky="nsew")
    label5.grid(column=0, row=4, sticky="nsew")
    label6.grid(column=0, row=5, sticky="nsew")
    label7.grid(column=0, row=6, sticky="nsew")
    label8.grid(column=0, row=7, sticky="nsew")
    label9.grid(column=0, row=8, sticky="nsew")
    label10.grid(column=2, row=4, sticky="nsew")
    button10_5.grid(column=2, row=0, sticky="nsew")
    button11.grid(column=2, row=1, sticky="nsew")
    button12.grid(column=2, row=2, sticky="nsew")
    button13.grid(column=2, row=3, sticky="nsew")
    entry14.grid(column=1, row=0, sticky="nsew")
    entry15.grid(column=1, row=1, sticky="nsew")
    entry16.grid(column=1, row=2, sticky="nsew")
    entry17.grid(column=1, row=3, sticky="nsew")
    entry18.grid(column=1, row=4, sticky="nsew")
    entry19.grid(column=1, row=5, sticky="nsew")
    entry20.grid(column=1, row=6, sticky="nsew")
    entry21.grid(column=1, row=7, sticky="nsew")
    entry22.grid(column=1, row=8, sticky="nsew")
    entry22_5.grid(column=3, row=0, sticky="nsew")
    entry23.grid(column=3, row=4, sticky="nsew")
    entry24.grid(column=3, row=1, sticky="nsew")
    entry25.grid(column=3, row=2, sticky="nsew")
    entry26.grid(column=3, row=3, sticky="nsew")
    button28.grid(column=2, row=5, sticky="nsew", columnspan=2)
    entry29.grid(column=2, row=6, sticky="nsew", columnspan=2)
    tickbox30.grid(column=2, row=7, sticky="nsew", columnspan=2)
    button27.grid(column=2, row=8, sticky="nsew", columnspan=2, rowspan=2)
    
    if not os.path.isfile(cur_dir+os.sep+'memory.cfg'):
        create_memory()
    config3 = configparser.ConfigParser()
    with open(cur_dir+os.sep+'memory.cfg') as f:
        config3.read_file(f)
    entry14.insert(0, config3['VALUES']['sigma1'])
    entry15.insert(0, config3['VALUES']['sigma2'])
    entry16.insert(0, config3['VALUES']['sigma3'])
    entry17.insert(0, config3['VALUES']['threshold1'])
    entry18.insert(0, config3['VALUES']['threshold2'])
    entry19.insert(0, config3['VALUES']['threshold3'])
    entry20.insert(0, config3['VALUES']['D12'])
    entry21.insert(0, config3['VALUES']['D13'])
    entry22.insert(0, config3['VALUES']['D23'])
    if len(config3['PATHS']['input_ch1']) > 20:
        entry24.insert(0, "..."+config3['PATHS']['input_ch1'][-20:])
    else:
        entry24.insert(0, config3['PATHS']['input_ch1'])
    if len(config3['PATHS']['input_ch2']) > 20:
        entry25.insert(0, "..."+config3['PATHS']['input_ch2'][-20:])
    else:
        entry25.insert(0, config3['PATHS']['input_ch2'])
    if len(config3['PATHS']['input_ch3']) > 20:
        entry26.insert(0, "..."+config3['PATHS']['input_ch3'][-20:])
    else:
        entry26.insert(0, config3['PATHS']['input_ch3'])
    if len(config3['PATHS']['output_dir']) > 17:
        entry29.insert(0, "..."+config3['PATHS']['output_dir'][-17:])
    else:
        entry29.insert(0, config3['PATHS']['output_dir'])
    chosen_dir = config3['PATHS']['output_dir']
    for i in range(3):
        input_list[i] = config3['PATHS']['input_ch%s' % (i+1)]
    
    

    # adding the folder name to the main dir
    # making sure the program stops, after the GUI is closed by pressing X

    def close_prot():
        root.destroy()
        sys.exit()
    root.protocol("WM_DELETE_WINDOW", close_prot)

    root.mainloop()
    os.mkdir(main_dir)
    
    if composite_input: #if input is a composite, the splitted images need to be saved
        io.imsave("{}/channel_1.tif".format(main_dir), red, check_contrast=False)
        io.imsave("{}/channel_2.tif".format(main_dir), green, check_contrast=False)
        if "Triple" in double_triple:#3-channel image
            io.imsave("{}/channel_3.tif".format(main_dir), blue, check_contrast=False)
    
    
    #creates the config files for each channel
    config = configparser.ConfigParser()
    config.optionxform = str  # makes the parser case-sensitive 
    with open(cfgtemp) as f:
        config.read_file(f)

    for i in range(3):
        try:
            os.mkdir(main_dir + r'/detection_ch%s' % (str(i+1)))
        except FileExistsError:
            pass

        input_dir = input_list[i]
        config.set('IO', 'output', value=str(main_dir + r'/detection_ch%s' % (str(i+1))))
        config.set('IO', 'input', value=str(input_dir))
        config.set('DETECTION', 'sigma', value=str(sigma[i]))
        config.set('DETECTION', 'basethreshold', value=str(threshold[i]))
        cfgdir = main_dir + r'/detection_ch%s/config_ch%s.cfg' % (str(i+1), str(i+1))
        with open(cfgdir, 'w+') as configfile:
            config.write(configfile, space_around_delimiters=False)
            if (double_triple == "Detection"): break #only once when detection mode active
            if (double_triple == "Double Colocalization" and i==1): break #only twice, when double coloc active


# opens the detection.jar file with the changed .cfg & calls the csv2points function
def detection(detfile, cfg):
    cfg_dir = main_dir + r'/detection_ch%s/config_ch%s.cfg' % (str(cfg), str(cfg))
    os.system(r'java -Xms512m -Xmx4g -jar ' + detfile + ' ' + cfg_dir) #add  -Xmx1500m if necessarry
    # csv2mdf
    mdf_input = main_dir + '/detection_ch%s/results/tracks' % (str(cfg))
    mdf_output = main_dir + '/detection_ch%s/results' % (str(cfg))
    os.system('perl ' + cur_dir + '/csv2mdf_actual_intens_area.pl ' + mdf_input + ' ' + mdf_output)
    if (double_triple != "Detection"): # only needed for colocalization
        csv2points(cfg_dir)
    


# reading the output directory from .cfg file
def csv2points(cfg_dir):
    config = configparser.ConfigParser()
    with open(cfg_dir) as f:
        config.read_file(f)
    tracks_dir = config.get('IO', 'output')
    points_dir = tracks_dir + os.sep+ 'points'
    points_list.append(points_dir)
    tracks_dir = tracks_dir + os.sep + 'results' + os.sep +'tracks'

    # checking if tracks are present in the track directory
    # converting tracks in output dir to points with csv2point
    if (len(os.listdir(path=tracks_dir)) != 0):
        os.system('python ' + cur_dir + os.sep + 'csv2points.py ' + str(tracks_dir) + ' ' + str(points_dir))


# output_coloc is the output directory of the colocalization; points_list is a list of the points directories
def colocalization(double_triple):
    # checking if tracks have been found for every single channel
    for point_dir in points_list:
        if os.path.exists(point_dir) == False:
            return
    if (double_triple == "Double Colocalization"):
        output_coloc = main_dir + r'/double_colocalization/results/ColocResults'
        os.mkdir(main_dir + r'/double_colocalization')
        os.mkdir(main_dir + r'/double_colocalization/rendered')
        os.mkdir(main_dir + r'/double_colocalization/results')
        os.system('python ' + cur_dir + os.sep + 'colocalization.py ' + points_list[0] + ' ' + points_list[1] + ' ' + d12 + ' ' + output_coloc)
        coloc = pd.read_csv(output_coloc)
        for channel in range(1,3):
            os.mkdir(main_dir + r"/double_colocalization/results/results_ch%s" % (str(channel)))
            os.mkdir(main_dir + r"/double_colocalization/results/results_ch%s/tracks_ch%s" % (str(channel), str(channel)))
    
        coloc2mdf(output_coloc, 1, 1, coloc, "double_")
        coloc2mdf(output_coloc, 2, 2, coloc, "double_")
        coloc_values_double(coloc, [1,2])
        csv2mdf(main_dir + r'/double_colocalization/results/coloc_data.csv', main_dir + r'/double_colocalization/results/coloc.mdf')
    elif (double_triple == "Triple Colocalization"):
        output_coloc = main_dir + r'/triple_colocalization/results/ColocResults'
        os.mkdir(main_dir + r'/triple_colocalization')
        os.mkdir(main_dir + r'/triple_colocalization/rendered')
        os.mkdir(main_dir + r'/triple_colocalization/results')
        os.system('python ' + cur_dir + os.sep + 'colocalization.py ' + points_list[0] + ' ' + points_list[1] + ' --points_ch_3 ' + points_list[2] + ' ' + d12 + ' --DmaxC1C3 ' + d13 + ' --DmaxC2C3 ' + d23 + ' ' + output_coloc)
        coloc = pd.read_csv(output_coloc)
        for channel in range(1,4):
            os.mkdir(main_dir + r"/triple_colocalization/results/results_ch%s" % (str(channel)))
            os.mkdir(main_dir + r"/triple_colocalization/results/results_ch%s/tracks_ch%s" % (str(channel), str(channel)))
    
        coloc2mdf(output_coloc, 1, 1, coloc, "triple_")
        coloc2mdf(output_coloc, 2, 2, coloc, "triple_")
        coloc2mdf(output_coloc, 3, 3, coloc, "triple_")
        coloc_values_triple(coloc)
        csv2mdf(main_dir + r'/triple_colocalization/results/coloc_data.csv', main_dir + r'/triple_colocalization/results/coloc.mdf')

def colocalization_twice(double_triple):
    # checking if tracks have been found for every single channel
    for point_dir in points_list:
        if os.path.exists(point_dir) == False:
            return
    double_channels = [double_triple[-7],double_triple[-2]]

    # triple coloc
    output_coloc_triple = main_dir + r'/triple_colocalization/results/ColocResults'
    os.mkdir(main_dir + r'/triple_colocalization')
    os.mkdir(main_dir + r'/triple_colocalization/results')
    os.mkdir(main_dir + r'/triple_colocalization/rendered')
    os.system('python ' + cur_dir + os.sep + 'colocalization.py ' + points_list[0] + ' ' + points_list[1] + ' --points_ch_3 ' + points_list[2] + ' ' + d12 + ' --DmaxC1C3 ' + d13 + ' --DmaxC2C3 ' + d23 + ' ' + output_coloc_triple)
    coloc = pd.read_csv(output_coloc_triple)
    for channel in range(1,4):
        os.mkdir(main_dir + r"/triple_colocalization/results/results_ch%s" % (str(channel)))
        os.mkdir(main_dir + r"/triple_colocalization/results/results_ch%s/tracks_ch%s" % (str(channel), str(channel)))
    
    coloc2mdf(output_coloc_triple, 1, 1, coloc, "triple_")
    coloc2mdf(output_coloc_triple, 2, 2, coloc, "triple_")
    coloc2mdf(output_coloc_triple, 3, 3, coloc, "triple_")
    coloc_values_triple(coloc)
    csv2mdf(main_dir + r'/triple_colocalization/results/coloc_data.csv', main_dir + r'/triple_colocalization/results/coloc.mdf')

    # double coloc
    output_coloc_double = main_dir + r'/double_colocalization/results/ColocResults'
    os.mkdir(main_dir + r'/double_colocalization')
    os.mkdir(main_dir + r'/double_colocalization/results')
    os.mkdir(main_dir + r'/double_colocalization/rendered')
    if "1" in double_channels and "2" in double_channels:
        os.system('python ' + cur_dir + os.sep + 'colocalization.py ' + points_list[0] + ' ' + points_list[1] + ' ' + d12 + ' ' + output_coloc_double)
    elif "1" in double_channels and "3" in double_channels:
        os.system('python ' + cur_dir + os.sep + 'colocalization.py ' + points_list[0] + ' ' + points_list[2] + ' ' + d13 + ' ' + output_coloc_double)
    elif "2" in double_channels and "3" in double_channels:
        os.system('python ' + cur_dir + os.sep + 'colocalization.py ' + points_list[1] + ' ' + points_list[2] + ' ' + d23 + ' ' + output_coloc_double)
    
    coloc = pd.read_csv(output_coloc_double)
    for channel in double_channels:
        os.mkdir(main_dir + r"/double_colocalization/results/results_ch%s" % (str(channel)))
        os.mkdir(main_dir + r"/double_colocalization/results/results_ch%s/tracks_ch%s" % (str(channel), str(channel)))
    
    coloc2mdf(output_coloc_double, int(double_channels[0]), 1, coloc, "double_")
    coloc2mdf(output_coloc_double, int(double_channels[1]), 2, coloc, "double_")
    coloc_values_double(coloc, double_channels)
    csv2mdf(main_dir + r'/double_colocalization/results/coloc_data.csv', main_dir + r'/double_colocalization/results/coloc.mdf')


def coloc_values_triple(coloc):
    counter = 0
    index = []
    tracks123 = coloc[['ID_ch1', 'ID_ch2', 'ID_ch3', 'start frame']].values
    # create empty dataframe of correct size
    for i in range(len(tracks123)):
        index.append(i)
    # , 'Intensity_mean' nicht beinhaltet in column namen
    data_df = pd.DataFrame(index=index, columns=['X_mean', 'Y_mean', 'frame', 'X_ch1', 'Y_ch1', 'Intensity_ch1', 'Area_ch1', 'X_ch2', 'Y_ch2', 'Intensity_ch2', 'Area_ch2', 'X_ch3', 'Y_ch3', 'Intensity_ch3', 'Area_ch3'])
    # readout intensity, area, x and y coordinates from Track.txts
    for colocalization in tracks123:
        line_list = []
        x_list = []
        y_list = []
        int_list = []
        for i in range(1, 4):
            with open(main_dir + os.sep +  "triple_colocalization/results/results_ch{}/tracks_ch{}/{}".format(i, i, colocalization[i-1])) as f:
                for line in f:
                    line = line.split(",")
                    data_df.iloc[counter, (i-1)*4+3] = line[1]
                    data_df.iloc[counter, (i-1)*4+4] = line[2]
                    data_df.iloc[counter, (i-1)*4+5] = line[3]
                    data_df.iloc[counter, (i-1)*4+6] = line[6]
                    x_list.append(float(line[1]))
                    y_list.append(float(line[2]))
                    int_list.append(float(line[3]))

        data_df.iloc[counter, 0] = sum(x_list)/3
        data_df.iloc[counter, 1] = sum(y_list)/3
        # data_df.iloc[counter, 2] = sum(int_list)/3
        data_df.iloc[counter, 2] = colocalization[3]+1
        
        counter += 1
    # save dataframe as csv
    data_df.sort_values(by = ["frame","X_mean","Y_mean"], inplace = True)
    data_df.reset_index(drop = True, inplace = True)
    data_df.to_csv(path_or_buf=main_dir + os.sep + "triple_colocalization" + os.sep + "results" + os.sep + "coloc_data.csv")

def coloc_values_double(coloc, double_channels):
    counter = 0
    index = []
    tracks12 = coloc[['ID_ch1', 'ID_ch2', 'start frame']].values
    # create empty dataframe of correct size
    for i in range(len(tracks12)):
        index.append(i)
    # , 'Intensity_mean' nicht beinhaltet in column namen
    data_df = pd.DataFrame(index=index, columns=['X_mean', 'Y_mean', 'frame', 'X_ch%s'%double_channels[0], 'Y_ch%s'%double_channels[0], 'Intensity_ch%s'%double_channels[0], 'Area_ch%s'%double_channels[0], 'X_ch%s'%double_channels[1], 'Y_ch%s'%double_channels[1], 'Intensity_ch%s'%double_channels[1], 'Area_ch%s'%double_channels[1]])
    # readout intensity, area, x and y coordinates from Track.txts
    for colocalization in tracks12:
        line_list = []
        x_list = []
        y_list = []
        int_list = []
        counter2 = 1
        for i in double_channels:
            with open(main_dir + "/double_colocalization/results/results_ch{}/tracks_ch{}/{}".format(i, i, colocalization[counter2-1])) as f:
                for line in f:
                    line = line.split(",")
                    data_df.iloc[counter, (counter2-1)*4+3] = line[1]
                    data_df.iloc[counter, (counter2-1)*4+4] = line[2]
                    data_df.iloc[counter, (counter2-1)*4+5] = line[3]
                    data_df.iloc[counter, (counter2-1)*4+6] = line[6]
                    x_list.append(float(line[1]))
                    y_list.append(float(line[2]))
                    int_list.append(float(line[3]))
            counter2 += 1

        data_df.iloc[counter, 0] = sum(x_list)/2
        data_df.iloc[counter, 1] = sum(y_list)/2
        # data_df.iloc[counter, 2] = sum(int_list)/3
        data_df.iloc[counter, 2] = colocalization[2]+1 # frame
        
        counter += 1
    # save dataframe as csv
    data_df.sort_values(by = ["frame","X_mean","Y_mean"], inplace = True)
    data_df.reset_index(drop = True, inplace = True)
    data_df.to_csv(path_or_buf=main_dir + os.sep + "double_colocalization" + os.sep + "results" + os.sep + "coloc_data.csv")
        
# sorts tracks from ch_1 in new directory; converts  them to mdf file in same directory
def coloc2mdf(output_coloc, channel, run_number, coloc, prefix):
    tracks = coloc[['ID_ch%s' % (run_number)]]
    for i in range(len(tracks)):
        src = main_dir + "/detection_ch%s/results/tracks/%s" % (str(channel), str(tracks.iloc[i][0]))
        dst = main_dir + os.sep + prefix + "colocalization/results/results_ch%s/tracks_ch%s/%s" % (str(channel), str(channel), str(tracks.iloc[i][0]))
        copyfile(src, dst)
    # creates .mdf file in in the same directory (not necessary at the moment)
    # coloctrack = main_dir + "\\colocalization\\results\\results_ch%s\\tracks_ch%s" % (str(channel), str(channel))
    # colocmdf = main_dir + "\\colocalization\\results\\results_ch%s" % (str(channel))
    # os.system('perl ' + cur_dir + '\\csv2mdf_intens_area.pl ' + coloctrack + ' ' + colocmdf)


def csv2mdf(input_dir, output_dir):
    with open(output_dir, "w+") as g:
        g.write("MTrackJ 1.3.0 Data File\nAssembly 1\nCluster 1\n")
        with open(input_dir, "r") as f:
            next(f)
            i = 1
            for line in f:
                line = line.rstrip()
                line = line.split(",")
                # mean_intensity = str((float(line[6])+float(line[10])+float(line[14]))/3)
                g.write("Track {}\n".format(i))
                g.write("Point 1 {} {} 1.0 {} 1\n".format(line[1], line[2], line[3]))
                i += 1
            for line in f:
                line = line.split(",")
        g.write("End of MTrackJ Data File\n")


def control_results():
    root = tkinter.Tk()
    root.iconify()
    root.title('Control')

    no_tracks = False
    empty_channels = []
    for i in range(1, 4):
        if os.path.isdir(main_dir + "/detection_ch%s/results/tracks" % (i)):
            if not os.listdir(main_dir + "/detection_ch%s/results/tracks" % (i)):
                no_tracks = True
                # print("No Tracks detected in Channel %s"%(i))
                empty_channels.append(i)
                if double_triple == "Detection":break  ## makes the testing work for detection mode
    if len(empty_channels) == 1:
        if double_triple == "Detection":
            tkinter.messagebox.showwarning("Warning", 'No tracks detected.')
        else:
            tkinter.messagebox.showwarning("Warning", 'No tracks detected in channel %s. Colocalization not possible.' % (empty_channels[0]))
    if len(empty_channels) == 2:
        tkinter.messagebox.showwarning("Warning", 'No tracks detected in channels %s and %s. Colocalization not possible.' % (empty_channels[0], empty_channels[1]))
    if len(empty_channels) == 3:
        tkinter.messagebox.showwarning("Warning", 'No tracks detected in channels %s, %s and %s. Colocalization not possible.' % (empty_channels[0], empty_channels[1], empty_channels[2]))

    isempty = False
    if not no_tracks:
        for i in range(1, 4):
            if os.path.isdir(main_dir + "/colocalization/results/results_ch%s/tracks_ch%s" % (i, i)):
                if not os.listdir(main_dir + "/colocalization/results/results_ch%s/tracks_ch%s" % (i, i)):
                    isempty = True
    if isempty:
        # print("No colocalization detected.")
        tkinter.messagebox.showwarning("Warning", 'Detection was successful. However, no colocating tracks were found.')
    if no_tracks is False and isempty is False:
        if double_triple == "Detection": 
            tkinter.messagebox.showinfo("Success", 'Detection was successful.')
        else:
            tkinter.messagebox.showinfo("Success", 'Detection and colocalization was successful.')
    root.destroy()
# defining necessary variables
double_triple = "Triple Colocalization" 
composite_input = False #Is a composite used as input?
cur_dir = os.path.dirname(os.path.realpath(__file__))
detfile = cur_dir + os.sep + "ColocQuant_SEF.jar"  # location of the detection file
cfgtemp = cur_dir + os.sep + "config_template.cfg"
points_list = []  # for saving points directories
chosen_dir = ""
input_list = ["", "", ""]

# check for operating system
if platform.system() == 'Windows':
    init_dir = "C:" + os.sep
    print(platform.system())

if platform.system() == 'Linux':
    init_dir = "~" + os.sep	

# calling the functions
files_present()
run_gui()
if (double_triple == "Detection"):
    detection(detfile, 1)
    control_results()
else:
    detection(detfile, 1)
    detection(detfile, 2)
    if ("Triple" in double_triple):
        detection(detfile, 3)
    if ("Triple and Double" in double_triple):
        colocalization_twice(double_triple)
    else: 
        colocalization(double_triple)
    control_results()
