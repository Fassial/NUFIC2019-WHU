#是文件路径,digit_total是数字总数,clf是SVM，model是数字识别模型
def recognize_number(src_addr,digit_total,clf,model):
    #print('src_addr is %s'%src_addr)

    # #我们通过FPGA进行切割，因此这一段不需要
    # pre_lost=2#前面去掉10
    # post_lost=2#后面去掉10
    # windowsize=10#窗长
    # hold_position=0

    #clf=SVC(gamma='auto',probability=True)
    #clf.fit(X_train,y_train)
    #joblib.dump(clf, 'cut.model')
    #clf=joblib.load('cut.model')#训练好了的SVM切割模型
    #src_addr='./bigdata/test/'+'036.csv'

    #################################################
    ##      这一段要着重改！！                       ##
    #################################################

    #这一段在读取数据，需要进一步修改去符合我们的设备
    df1=pd.read_csv(src_addr)
    df=df1[pre_lost:-post_lost].reset_index(drop=True)

    #if(hold_position==0):#如果和数据库中一样
    #    ax=df.ACCx.rolling(window=int(windowsize/2)).mean().values
    #    az=df.ACCz.rolling(window=int(windowsize/2)).mean().values
    #    ay=df.ACCy.rolling(window=int(windowsize/2)).mean().values
    #else:#水平横着拿手机的,z=-x,x=y
    #    az=df.ACCx.rolling(window=int(windowsize/2)).mean().values
    #    ay=df.ACCz.rolling(window=int(windowsize/2)).mean().values
    #    ax=df.ACCy.rolling(window=int(windowsize/2)).mean().values
    #    az=-az

    ax=df.ACCx.values
    ay=df.ACCy.values
    az=df.ACCz.values

    #ax[0:int(windowsize/2)-1]=ax[int(windowsize/2)-1:int(windowsize/2)*2-2]
    #ay[0:int(windowsize/2)-1]=ay[int(windowsize/2)-1:int(windowsize/2)*2-2]
    #az[0:int(windowsize/2)-1]=az[int(windowsize/2)-1:int(windowsize/2)*2-2]
    #ax=ax-ax.mean()
    #ay=ay-ay.mean()
    #az=az-az.mean()

    # #计算能量阈值，这些我们在FPGA里面已经进行了
    # energy_x=ax*ax
    # energy_y=ay*ay
    # energy_z=az*az
    # energy_total=energy_x+energy_y+energy_z


    # 这一段是在切割，因为之前华为手机数据的问题，想了比较多的方法
    # try:
    #     dx=(df.ACCx.rolling(window=int(windowsize/2)).var()).values
    #     dy=(df.ACCy.rolling(window=int(windowsize/2)).var()).values
    #     dz=(df.ACCz.rolling(window=int(windowsize/2)).var()).values
    #
    #
    #     #对于开头的NaN的处理
    #     dx[0:int(windowsize/2)-1]=dx[int(windowsize/2)-1:int(windowsize/2)*2-2]
    #     dy[0:int(windowsize/2)-1]=dy[int(windowsize/2)-1:int(windowsize/2)*2-2]
    #     dz[0:int(windowsize/2)-1]=dz[int(windowsize/2)-1:int(windowsize/2)*2-2]
    #
    #     #加速度的变化率
    #     delta_ax=np.zeros((len(ax)))
    #     delta_ay=np.zeros((len(ax)))
    #     delta_az=np.zeros((len(ax)))
    #     for i in range(len(ax)-1):
    #         delta_ax[i]=ax[i+1]-ax[i]
    #         delta_ay[i]=ay[i+1]-ay[i]
    #         delta_az[i]=az[i+1]-az[i]
    # except:
    #     return('0000')
    #
    # index=0#总的索引
    #
    # num_seg=[]
    #
    # may_num_flag=0#可能是数字段
    # must_num_flag=0#已经判断是数字段了
    # num_seg_begin=0#数字段内开始位置
    # num_seg_end=0#数字段内结束位置
    # num_write_length_add=0#数字段长度计数
    # num_gap_length_add=0#数字段掉下去间隔计数
    # num_wait_length=0#在等待第2阈值
    #
    # may_quiet_flag=0#可能是静止段标志
    # quiet_seg_begin=0#静止段内开始位置
    # quiet_seg_end=0#静止段结束位置
    # quiet_seg_length=0
    #
    # y_pred=np.zeros(len(ax))
    # seg_num=0#总共发现了多少个段落
    #
    # current_flag=0#当前是在搜索什么，判断这个段目前是什么
    #
    # #长度和阈值达到才是在写
    # heigth_OK=0#阈值达到
    # length_OK=0#长度达到
    #
    # write_thre_1=2.5#能量第1阈值
    # write_thre_2=4#能量第2阈值
    # quiet_thre=2#静止区域
    # num_min_len=30#书写区域长度阈值
    # num_max_wait=15#最长等待间隔
    # num_max_gap=8#最长间隔
    #
    #
    #
    # while(index<len(ax)):
    #     if(energy_total[index]>=write_thre_2):#达到第2阈值，很OK了
    #         #heigth_OK=1#幅度阈值达到，肯定就是了
    #         if(may_num_flag==0):
    #             may_num_flag=1
    #             num_seg_begin=index
    #             num_wait_length=0
    #             num_write_length_add=1
    #         elif(must_num_flag==1 and may_quiet_flag==1):#可能快掉下去了
    #             num_write_length_add=num_write_length_add+quiet_seg_length#加上长度
    #         elif(may_num_flag==1 and may_quiet_flag==0 and must_num_flag==0):
    #             num_write_length_add=num_wait_length
    #         else:
    #             num_write_length_add=num_write_length_add+1
    #         must_num_flag=1#确凿无疑是数字段
    #         may_quiet_flag=0#肯定不是静音区域了
    #         quiet_seg_length=0
    #     elif(energy_total[index]>=write_thre_1):#达到第1阈值，可能是数字段，不是很确定
    #         if(may_num_flag==0):
    #             may_num_flag=1
    #             num_seg_begin=index
    #             num_wait_length=1
    #         elif(may_num_flag==1 and may_quiet_flag==1):
    #             if(must_num_flag==0):#还在等待
    #                 num_wait_length=num_wait_length+1
    #                 if(num_wait_length>=num_max_wait):#误报，没有在写
    #                     may_num_flag=0
    #                     num_wait_length=0
    #                     must_num_flag=0
    #             else:#只是书写区域出现了短时的静音区
    #                 num_write_length_add=num_write_length_add+quiet_seg_length
    #             may_quiet_flag=0
    #             quiet_seg_length=0
    #         elif(may_quiet_flag==0):
    #             num_write_length_add=num_write_length_add+1
    #
    #     elif(energy_total[index]<=quiet_thre):
    #         if( (may_num_flag==1 or must_num_flag==1) and may_quiet_flag == 0 ):
    #             may_quiet_flag=1
    #             quiet_seg_length=1
    #         elif( (may_num_flag==1 or must_num_flag==1) and may_quiet_flag == 1 ):
    #             quiet_seg_length=quiet_seg_length+1
    #             if(quiet_seg_length >= num_max_gap):
    #                 if(num_write_length_add >= num_min_len):#大于最小长度
    #                     num_seg_end=index
    #                     num_seg.append([num_seg_begin,num_seg_end])
    #                 may_quiet_flag=0
    #                 must_num_flag=0
    #                 may_num_flag=0
    #                 num_write_length_add=0
    #                 num_wait_length=0
    #                 quiet_seg_length=0
    #
    #     else:
    #         if(may_num_flag==1 and must_num_flag==0):
    #             num_wait_length=num_wait_length+1
    #         elif(must_num_flag==1):
    #             num_write_length_add=num_write_length_add+1
    #
    #     index=index+1
    #
    # if(may_num_flag==1):
    #     if(num_write_length_add>=num_min_len):#如果是在写，有效
    #         num_seg_end=index-quiet_seg_length
    #         if(num_seg_end>=len(ax)):
    #             num_seg_end=len(ax)-1
    #         num_seg.append([num_seg_begin,num_seg_end])
    #         may_num_flag=0
    #
    #
    # for item in num_seg:
    #     y_pred[item[0]:item[1]]=1
    #
    # index=0
    # segment=[]#有效的段,应该是digit_total个
    # while index<len(y_pred):
    #     current_area_index_begin=index
    #     current_flag=y_pred[index]
    #     #向后查找,确定当前块有多长
    #     current_area_len=1
    #     if(index+1<len(y_pred)):
    #         temp_index_ptr=index+1
    #         current_area_len=1
    #         if(current_flag==y_pred[temp_index_ptr]):#如果后面还有
    #             current_area_len=current_area_len+1
    #             while(temp_index_ptr+1<len(y_pred)):
    #                 temp_index_ptr=temp_index_ptr+1
    #                 if(current_flag==y_pred[temp_index_ptr]):#如果是连续的
    #                     current_area_len=current_area_len+1
    #                 else:#否则到此结束
    #                     break
    #     if(current_flag==1):
    #         segment.append(df[current_area_index_begin:current_area_index_begin+current_area_len])
    #     index=index+current_area_len
    #
    # ifpredict=1
    #
    # if(len(segment)<digit_total):
    #     print('%d gap too short or write too slow'%len(segment))
    #     return('0'*digit_total)

    if(ifpredict==1):
        maxlen=800#每个数字至多这么多时间
        X_test=np.zeros((digit_total,int(maxlen),3))

        #这一段是在做不同数字的区分，我们可以最后再看，先把一个数字的做好
        # if(len(segment)>digit_total):
        #     s_len=np.zeros(len(segment),dtype=np.int32)
        #     for i in range(len(segment)):
        #         s_len[i]=len(segment[i])
        #     max_item=s_len.argsort()[-(digit_total):][::-1]
        #     rm_item=list(set(range(len(segment)))-set(max_item))
        #     for k in rm_item:
        #         del segment[k]


        digit_total = 1;#识别数字，本来是函数输入，现在我们改接口之后可能要重新做一下

        #这一段可能还可以改一改，但是为了可拓展性，保留了相关代码

        if(1):
            try:
                for i in range(digit_total):
                    temp=np.zeros((3,maxlen))
                    temp[0][0:len(segment[i].ACCx)]=segment[i].ACCx
                    temp[1][0:len(segment[i].ACCy)]=segment[i].ACCy
                    temp[2][0:len(segment[i].ACCz)]=segment[i].ACCz
                    temp=temp.T
                    X_test[i]=temp

                #这一段是在做数据处理，可以尝试一下
                for k in range(len(X_test)):
                    X_test[k][0:len(segment[k].ACCx)]=StandardScaler().fit_transform(X_test[k][0:len(segment[k].ACCx)])#标准化!
                    X_test[k][len(segment[k].ACCx):]=0
                num_prob=model.predict(X_test)
                #print('predict %d'%i)
                num_pred=np.zeros(len(num_prob),dtype=np.int32)
                for i in range(len(num_prob)):
                    num_pred[i]=np.argmax(num_prob[i])
            except:
                num_pred=np.zeros(digit_total,dtype=np.int32)
                for i in range(digit_total):
                    num_pred[i]=0
            print(num_pred)
            return(num_pred)


        #except:
        #    return('0'*digit_total)

#num_pred=recognize_number('./csv/1562831289830.csv',10,clf,model)
#num_pred=recognize_number('./csv/28013.csv',10,clf,model)
