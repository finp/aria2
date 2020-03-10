#!/bin/sh
content_dir=$3
files_num=$2
task_id=$1
downloadpath='/home/aDown' # 下载目录-需要和aria2一致
log_dir="/home/.aria2"  # 这里是存放log的地方-默认和aria放在一起
rclone_dest="gd"        # rclone的disk名称-需要修改
rpc_pwd="123"           # aria2的rpc的密码-需要修改
rpc_url="http://xxx.xxx.xxx:6800/jsonrpc" # aria2的rpc地址--需要修改

rclone_parallel="32"


if [ ! -d ${log_dir} ]
then
        mkdir -p ${log_dir}
fi

tmp_dir=$content_dir
echo "原始目录：${content_dir}" >> ${log_dir}/ariaUP.log
while true; do  #提取下载文件根路径，如把/data/a/b/c/d.jpg变成/data/a
    content_dir="${tmp_dir}"
    tmp_dir=${tmp_dir%/*};
   
    if test -z "${tmp_dir}"
        then
        break
    elif [ "${tmp_dir}" = "${downloadpath}" ] && [ $2 -eq 1 ]
        then
        break
    elif [ "${tmp_dir}" = "${downloadpath}" ]   #文件夹
        then
        break
    fi
done

if [ "${files_num}" = "0" ]
   then
   echo -e "\t文件数量为0 直接跳过\n" >> ${log_dir}/ariaUP.log
   exit
fi

if [ "${content_dir}" = "/" ] || [ "${tmp_dir}" != "${downloadpath}" ]
    then
    echo -e "\t路径异常${tmp_dir} 直接跳过\n" >> ${log_dir}/ariaUP.log
    exit
fi

# 提取其中的相对路径-这个路径就比较绝对了
relative_dir="${content_dir/${downloadpath}/}" # 移除downloadpath内容后的content_dir
relative_dir="${relative_dir:1}" # 移除掉坐起斜杠
echo "相对路径：${relative_dir}" >> ${log_dir}/ariaUP.log


function rclone_copy(){
    if [ ${type} == "file" ]
    then
        rclone_copy_cmd=$(rclone -v copy --transfers ${rclone_parallel} --log-file  ${log_dir}/ariaUP.log "${content_dir}" ${rclone_dest}:)
    elif [ ${type} == "dir" ]
    then
        rclone_copy_cmd=$(rclone -v copy --transfers ${rclone_parallel} --log-file  ${log_dir}/rloneUP.log "${content_dir}" ${rclone_dest}:"${relative_dir}")
    fi
    # echo '';
}
function rclone_del(){
        rm -rf "${content_dir}";
        rm -rf "${content_dir}.aria2";
        curl -X POST -d "{"jsonrpc":"2.0","method":"aria2.removeDownloadResult","id":"mjj","params":["token:${rpc_pwd}","${task_id}"]}" "${rpc_url}"
        # echo '';
}

if [ -f "${content_dir}" ]
then
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] 类型：文件 ${content_dir}" >> ${log_dir}/ariaUP.log
   type="file"
   rclone_copy
   rclone_del
elif [ -d "${content_dir}" ]
then
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] 类型：目录 ${content_dir}" >> ${log_dir}/ariaUP.log
   type="dir"
   rclone_copy
   rclone_del
else
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] 未知类型，取消上传" >> ${log_dir}/ariaUP.log
fi

echo "内容路径：${content_dir}" >> ${log_dir}/ariaUP.log
echo "上传路径：${rclone_dest}:${relative_dir}" >> ${log_dir}/ariaUP.log
echo "文件数：${files_num}" >> ${log_dir}/ariaUP.log
echo -e "-------------------------------------------------------------\n" >> ${log_dir}/ariaUP.log
