loading () {
        endload=/tmp/$me.load
        (while [ ! -f $endload ];do
                echo -ne "\rLoading   " && \
                sleep 0.25 && echo -ne "\rLOading.  " && \
                sleep 0.25 && echo -ne "\rLoAding . " && \
                sleep 0.25 && echo -ne "\rLoaDing . " && \
                sleep 0.25 && echo -ne "\rLoadIng  ." && \
                sleep 0.25 && echo -ne "\rLoadiNg.  " && \
                sleep 0.25 && echo -ne "\rLoadinG.. " && \
                sleep 0.25 && echo -ne "\rLoading..." && sleep 0.25
        done
        echo -e "\e[36;1msucceed\e[0m~ Modify codes..."
        rm -rf $endload) &
}
