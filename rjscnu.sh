#! /bin/bash

# 切换到脚本所在目录
cd "$(dirname "$(realpath "$0")")" || exit 1

ARGS=""
rjpath="./rjsupplicant/rjsupplicant.sh"

# 从配置文件中读取并构建 --key value 形式的参数
while IFS='=' read -r key value; do
    # 排除注释和空行
    if [[ -n "$key" && -n "$value" && "$key" != \#* ]]; then
        ARGS="$ARGS --$key \"$value\""
    fi
done < ./args.cfg
# 如果有命令行参数，覆盖配置文件中的值
while [[ $# -gt 0 ]]; do
    arg="$1"
    ARGS="$ARGS $arg"
    shift
done

# 检查互联网连接
check_internet() {
    echo "正在检查互联网连接"
    ping -c 1 -W 3 223.5.5.5 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# 杀死关键进程
kill_rjsupplient() {
    key_pid=$(ps aux | grep -E "Sl\+.*rjsupplicant" | grep -v grep | awk '{print $2}')
    if [ -z "$key_pid" ]; then
        echo "没有匹配的关键进程"
        exit 1
    else
        echo "找到关键进程: $key_pid, 正在杀死"
        kill -9 $key_pid
        echo "不出意外你可以上网了>_<"
    fi
}

# 实时读取输出并检查关键字
monitor_output() {
    while read -r line; do
        echo "$line"
        # 检查关键字
        if [[ "$line" =~ "认证成功" ]]; then
                kill_rjsupplient  # 调用处理函数
                break
        fi
    done < <(tail -f "$1")
}

# 启动认证客户端，并将输出重定向到log文件
start_rjsupplicant() {
    command="$rjpath $ARGS"
    echo "执行命令: $command"
    $command > output.log 2>&1 &
    rj_pid=$!
    echo " 锐捷客户端启动, PID: $rj_pid"
}

# 主函数
main() {
    # 检查互联网连接
    check_internet
    is_connected=$?
    if [ $is_connected -eq 0 ]; then
        echo "已有互联网连接"
    else
        start_rjsupplicant  # 启动程序
        monitor_output "output.log"  # 监控输出文件并检查关键字
    fi
    exit 0
}


main

