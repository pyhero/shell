#!/bin/sh

for k in {12..12}; do
    for i in {01..31}; do
        dt="2015-$k-$i"
        # file="/ROOT/log/php/info.modian.com/$dt-l.log"
        file="/ROOT/log/php/info.modian.com/$dt-access-valid.log"

        if [ -f $file ]; then
            echo -ne "\n$dt:\n"

            printf "\t%-15s\t" "全站"
            awk -F '{print $13}' $file | wc -l | tr -t '\n' '\t'
            awk -F '{print $13}' $file | sort| uniq | wc -l

            printf "\t%-15s\t" "www站"
            awk -F '$3 ~ /"www.modian.com"/ {print $3,$13}' $file | wc -l | tr -t '\n' '\t'
            awk -F '$3 ~ /"www.modian.com"/ {print $3,$13}' $file | sort| uniq | wc -l

            printf "\t%-15s\t" "社区"
            awk -F '$3 ~ /"moximoxi.modian.com"/ {print $3,$13}' $file | wc -l | tr -t '\n' '\t'
            awk -F '$3 ~ /"moximoxi.modian.com"/ {print $3,$13}' $file | sort| uniq | wc -l
            # echo -ne "$dt,"
            # awk -F '$3 ~ /"moximoxi.modian.com"/ {print $3,$13}' $file | wc -l | tr -t '\n' ','

            printf "\t%-15s\t" "m站"
            awk -F '$3 ~ /"m.modian.com"/ {print $3,$13}' $file | wc -l | tr -t '\n' '\t'
            awk -F '$3 ~ /"m.modian.com"/ {print $3,$13}' $file | sort| uniq | wc -l

            printf "\t%-15s\t" "zhongchou站"
            awk -F '$3 ~ /"zhongchou.modian.com"/ {print $3,$13}' $file | wc -l | tr -t '\n' '\t'
            awk -F '$3 ~ /"zhongchou.modian.com"/ {print $3,$13}' $file | sort| uniq | wc -l

            printf "\t%-15s\t" "login站"
            awk -F '$3 ~ /"login.modian.com"/ {print $3,$13}' $file | wc -l | tr -t '\n' '\t'
            awk -F '$3 ~ /"login.modian.com"/ {print $3,$13}' $file | sort| uniq | wc -l

            printf "\t%-15s\t" "me站"
            awk -F '$3 ~ /"me.modian.com"/ {print $3,$13}' $file | wc -l | tr -t '\n' '\t'
            awk -F '$3 ~ /"me.modian.com"/ {print $3,$13}' $file | sort| uniq | wc -l

            # echo -ne "$dt\t"
            # awk -F '$4 ~ /"http:\/\/huodong.modian.com\/redwallet.*"/ {print $13}' $file | wc -l | tr -t '\n' '\t'
            # awk -F '$4 ~ /"http:\/\/huodong.modian.com\/redwallet.*"/ {print $13}' $file | sort| uniq | wc -l

            # echo -ne "$dt,"
            # awk -F '$4 ~ /^"http:\/\/(m|www|zhongchou).modian.com\/(item|project)\/1134.html.*"$/ ||
            #             $4 ~ /^"http:\/\/(m|www|zhongchou).modian.com\/(item|project)\/update\/1134.html\??.*"$/ ||
            #             $4 ~ /^"http:\/\/(m|www|zhongchou).modian.com\/(item|main)\/(comments|comment|reply|reply_list)\/1134.*"$/ ||
            #             $4 ~ /^"http:\/\/(m|www|zhongchou).modian.com\/(item|project)\/backer\/1134.html\??.*"$/ ||
            #             $4 ~ /^"http:\/\/(m|www|zhongchou).modian.com\/pay\/\?(id=1134+&pid=[0-9]+|pid=[0-9]+&id=1134).*"$/ ||
            #             $4 ~ /^"http:\/\/(m|www|zhongchou).modian.com\/pay\/pay_success\?(pay_id=[0-9]+&xid=1134).*"$/ {print $13, $4}' $file | wc -l | tr -t '\n' ','
            # awk -F '$4 ~ /^"http:\/\/(m|www|zhongchou).modian.com\/(item|project)\/1134.html.*"$/ ||
            #             $4 ~ /^"http:\/\/(m|www|zhongchou).modian.com\/(item|project)\/update\/1134.html\??.*"$/ ||
            #             $4 ~ /^"http:\/\/(m|www|zhongchou).modian.com\/(item|main)\/(comments|comment|reply|reply_list)\/1134.*"$/ ||
            #             $4 ~ /^"http:\/\/(m|www|zhongchou).modian.com\/(item|project)\/backer\/1134.html\??.*"$/ ||
            #             $4 ~ /^"http:\/\/(m|www|zhongchou).modian.com\/pay\/\?(id=1134+&pid=[0-9]+|pid=[0-9]+&id=1134).*"$/ ||
            #             $4 ~ /^"http:\/\/(m|www|zhongchou).modian.com\/pay\/pay_success\?(pay_id=[0-9]+&xid=1134).*"$/ {print $13, $4}' $file | sort| uniq | wc -l
        fi
    done
done



