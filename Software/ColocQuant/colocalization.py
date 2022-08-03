import argparse
import pandas as pd
import numpy as np
import os
from itertools import groupby
from scipy.spatial import KDTree

def colocalization(points_path_1, points_path_2, points_path_3, DmaxC1C2, DmaxC1C3, DmaxC2C3, out_file):

    # coloc all channels
    list_ind = build_tree(points_path_1, points_path_2, points_path_3, DmaxC1C2, DmaxC1C3, DmaxC2C3)
    
    ID_ch1       = []
    ID_ch2       = []
    ID_ch3       = []
    time_total   = []
    time_max     = []
    start        = []
    end          = []

    for elem, elem_count in count_all_elements(list_ind):
    
        #prepare Track IDs (strings) for ouput file
        for i in elem:
            if '_1.' in i:
                ID_help_ch1 = i.replace('_1.','.') 
            if '_2.' in i:
                ID_help_ch2 = i.replace('_2.','.') 
            if points_path_3 is not None:
                if '_3.' in i:
                    ID_help_ch3 = i.replace('_3.','.') 

        ID_ch1.append(ID_help_ch1)  
        ID_ch2.append(ID_help_ch2)  
        if points_path_3 is not None:
            ID_ch3.append(ID_help_ch3)  
        time_total.append(elem_count[0])
        time_max.append(elem_count[1])
        start.append(elem_count[2])
        end.append(elem_count[3])

    #make data frame for output file        
    analysis_pd = pd.DataFrame()
    analysis_pd['ID_ch1'] =  ID_ch1
    analysis_pd['ID_ch2'] =  ID_ch2
    if points_path_3 is not None:
        analysis_pd['ID_ch3'] =  ID_ch3
    analysis_pd['total_coloc_time'] =  time_total
    analysis_pd['max_coloc_time'] =  time_max
    analysis_pd['start frame'] =  start
    analysis_pd['end frame'] =  end
    analysis_pd.to_csv(out_file,index=False)         




def count_all_elements(list_ind):
    
    all_elem = set([]).union(*list_ind)
    for elem in all_elem:
        yield elem, count_occurances(elem, list_ind)




def count_occurances(elem, list_ind):

    mask = get_mask(elem, list_ind)   
    total_time = sum(mask)
    consecutive_frames = [list(i[1]) for i in groupby(mask, key=lambda i:i==0)]
    max_t   = 0
    counter = 0

    for i in consecutive_frames:
        counter = counter+len(i)
        if 0 not in i: 
            if len(i)> max_t:
                    start = counter-len(i)
                    end = start+len(i)-1
                    max_t = len(i)
                                                 
    return (total_time, max_t, start, end)
    
    


def get_mask(elem, list_ind):
    
    if not isinstance(elem, frozenset): elem = frozenset(list(elem))
    
    return [1 if elem in timeframe else 0 for timeframe in list_ind]
    
    
 
 
def makeID(ID_ch1,ID_ch2,a, b, ind):

    inserta = '_'+str(a)+'.'
    insertb = '_'+str(b)+'.'
    
    new_ID_ch2 = []
    T_ch2=[]
    T_ch1=[]
    for i in range(0,len(ind)):
        if len(ind[i])>0:
            for j in ind[i]:
                string = ID_ch2[j].split('.')
                string = string[0]+insertb+string[1]
                T_ch2.append(string)
                string = ID_ch1[i].split('.')
                string = string[0]+inserta+string[1]
                T_ch1.append(string)
            
    set_ID=[]
    for i,j in zip(T_ch1,T_ch2):
        set_ID.append(frozenset([i,j]))
    return(set_ID)




def build_tree(points_path_1, points_path_2, points_path_3, DmaxC1C2, DmaxC1C3, DmaxC2C3):  
    
    #do colocalization based on KDTree
    list_ind = []

    if len(os.listdir(points_path_1)) == len(os.listdir(points_path_2)):
        
        for i in range(0,len(os.listdir(points_path_1))):
            points_ch1 = pd.read_csv(points_path_1+'/trackingResults_t'+str(i)+'.csv', header=None).values.T
            points_ch2 = pd.read_csv(points_path_2+'/trackingResults_t'+str(i)+'.csv', header=None).values.T
               
            #ID        
            ID_ch1 = points_ch1[3]
            ID_ch2 = points_ch2[3]
      
            #Positions
            p_ch1  = points_ch1[0:3].T
            p_ch1 = p_ch1.astype(float)
        
            p_ch2  = points_ch2[0:3].T
            p_ch2 = p_ch2.astype(float)
                          
            #colocalization    
            tree  = KDTree(p_ch2)   
            ind_ch12   = tree.query_ball_point(p_ch1, r=DmaxC1C2)
            set_ID12 = makeID(ID_ch1,ID_ch2,1,2,ind_ch12)

            if points_path_3 is not None: 
                points_ch3 = pd.read_csv(points_path_3+'/trackingResults_t'+str(i)+'.csv', header=None).values.T                
                ID_ch3 = points_ch3[3]
                p_ch3  = points_ch3[0:3].T
                p_ch3 = p_ch3.astype(float)

                tree  = KDTree(p_ch2)
                if DmaxC2C3 is not None:   
                    ind_ch23   = tree.query_ball_point(p_ch3, r=float(DmaxC2C3))
                else:
                    ind_ch23   = tree.query_ball_point(p_ch3, r=DmaxC1C2)
                set_ID23 = makeID(ID_ch3,ID_ch2,3,2,ind_ch23)

                tree  = KDTree(p_ch3)
                if DmaxC1C3 is not None:
                    #print()   
                    ind_ch13   = tree.query_ball_point(p_ch1, r=float(DmaxC1C3))
                else:
                    ind_ch13   = tree.query_ball_point(p_ch1, r=float(DmaxC1C2))
                set_ID13 = makeID(ID_ch1,ID_ch3,1,3,ind_ch13)  
                
                #build three channel set
                set_ID = set_ID12+set_ID23+set_ID13

                intersect_list = []
                for i in range(0,len(set_ID)):
                    for j in range(0,len(set_ID)):
                        if i != j:
                            if len(set_ID[i].intersection(set_ID[j])) !=0:
                                diff = set_ID[i].symmetric_difference(set_ID[j])
                                for k in range(0,len(set_ID)):
                                    if set_ID[k].issubset(diff) == True:
                                        coloc = diff.union(set_ID[i].intersection(set_ID[j]))
                                        intersect_list.append(coloc)
                coloc_points=set(intersect_list)
            else:
            
                #build three channel set
                set_ID = set_ID12
                intersect_list = []
                for i in range(0,len(set_ID)):
                    coloc = set_ID[i]
                    intersect_list.append(coloc)               
                     
                coloc_points=set(intersect_list)

            list_ind.append(coloc_points)

    else:
        raise NameError('Dimension missmatch between detection folders.')
    
    return (list_ind)    





if __name__ == "__main__":
    
    parser = argparse.ArgumentParser()
    parser.add_argument('points_ch_1', type=str, help='Detection folder of channel 1')
    parser.add_argument('points_ch_2', type=str, help='Detection folder of channel 2')
    parser.add_argument('--points_ch_3', type=str, help='Detection folder of channel 3', default=None)
    parser.add_argument('DmaxC1C2', type=float, help='max. distance for beeing colocalized (C1-C2)')
    parser.add_argument('--DmaxC1C3', type=str, help='max. distance for beeing colocalized (C1-C3)', default=None)
    parser.add_argument('--DmaxC2C3', type=str, help='max. distance for beeing colocalized (C2-C3)', default=None)
    parser.add_argument('out_file', type=str, help='csv file with colocalization analysis')
    

    args        = parser.parse_args()
    points_ch_1 = args.points_ch_1
    points_ch_2 = args.points_ch_2
    points_ch_3 = args.points_ch_3
    DmaxC1C2    = args.DmaxC1C2
    DmaxC1C3    = args.DmaxC1C3
    DmaxC2C3    = args.DmaxC2C3
    out_file    = args.out_file

    #tool
    coloc_analysis = colocalization(points_ch_1, points_ch_2, points_ch_3, DmaxC1C2, DmaxC1C3, DmaxC2C3, out_file)
 






