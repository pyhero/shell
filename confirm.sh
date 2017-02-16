confirm () {
        while read -p "Sure?{y|n}: " inp;do
        case $inp in
                y)
                        rev=1
                        break
                        ;;
                n)
                        rev=0
                        break
                        ;;
                *)
                        rev=0
                        continue
        esac
        done
        if [ $rev=1 ];then
                break
        else
                continue
        fi
}

confirm
