#!/bin/bash

GIT_STATUS=git_status.txt
GIT_BRANCH=git_branch.txt

SEARCH_KEY=modified:

RUN_OK=0
RUN_FAIL=1

function git_status ()
{
    local L_LINE_NUM=0

    echo "start to run git status,please wait a moment......"

    # run git status
    if [ ! -f ${GIT_STATUS} ];
    then
	git status > ${GIT_STATUS}

	if [ ! -f ${GIT_STATUS} ];
	then
	    echo "git status filed!"
	
	    return ${RUN_FAIL};
	fi
    else
	echo "The git stauts file have exist,do you need update the ${GIT_STATUS} file?y/n"
	read isUpdate

	if [ "y" == ${isUpdate} ];
	then
	    git status > ${GIT_STATUS}_bak

	    L_LINE_NUM=$(grep -c "${SEARCH_KEY}" ${GIT_STATUS}_bak)

	    if [ 0 == L_LINE_NUM ];
	    then
                echo "there is nothing that be modified!"

		rm ${GIT_STATUS}_bak

		return ${RUN_FAIL};
	    fi
	    
	    if [ ! -f ${GIT_STATUS}_bak ];
            then
	        echo "git status filed!"
	        
		return ${RUN_FAIL};
            fi
	    
	    LINE_NUM=$(grep -c "${SEARCH_KEY}" ${GIT_STATUS})

	    if (( ${LINE_NUM} > ${L_LINE_NUM} ));
	    then
		echo "you can't update the ${GIT_STATUS} file, use the old ${GIT_STATUS} file!"

		rm ${GIT_STATUS}_bak

		return ${RUN_FAIL};
	    else
		mv ${GIT_STATUS}_bak ${GIT_STATUS}
	    fi
	fi
    fi

    LINE_NUM=$(grep -c "${SEARCH_KEY}" ${GIT_STATUS})

    if [ 0 == LINE_NUM ];
    then
	return ${RUN_FAIL};
    fi
}

function find_modified_files ()
{
    # find the modified files
    for(( i=1; i<=${LINE_NUM}; i++ ));
    do
	MODIFIED_FILE=$(grep "${SEARCH_KEY}" ${GIT_STATUS} | sed -n ${i}p | awk '{print $3}')
	echo ${MODIFIED_FILE}

	if [ ! -f ${MODIFIED_FILE}_bak ];
	then
	   cp ${MODIFIED_FILE} ${MODIFIED_FILE}_bak

           if [ 0 != $? ];
           then
	       return ${RUN_FAIL};
	   fi 
	fi  
    done
}

function git_checkout ()
{
    echo "are you sure you will run the git checkout .?y/n"

    read isCheckOut

    if [ "y" == ${isCheckOut} ];
    then  
        echo "start to run git checkout .,please wait a moment......"

        git checkout .
    else
        return ${RUN_FAIL}
    fi  
}

function create_temp_files ()
{
    for(( i=1; i<=${LINE_NUM}; i++ ));
    do
        MODIFIED_FILE=$(grep "${SEARCH_KEY}" ${GIT_STATUS} | sed -n ${i}p | awk '{print $3}')
        cp ${MODIFIED_FILE} ${MODIFIED_FILE}_old

	if [ 0 != $? ];
        then
	    return ${RUN_FAIL};
	fi    

    done
}

function get_branch_num ()
{
    git fetch --all

    echo "Which branch do you wanna update?"
    git branch -r > ${GIT_BRANCH}

    BRANCH_NUM=$(grep -c "origin" ${GIT_BRANCH})

    if [ 0 == BRANCH_NUM ];
    then
	return ${RUN_FAIL};
    fi	

    echo $(grep "origin/HEAD" ${GIT_BRANCH})

    for(( i=1; i<${BRANCH_NUM}; i++ ));
    do
	let j=i+1
	echo ${i}: $(grep "origin" ${GIT_BRANCH} | sed -n ${j}p)
    done
}

function update_code ()
{
    read branchNum

    let i=branchNum+1

    if (( ${BRANCH_NUM} < ${i} ));
    then
	return ${RUN_FAIL};
    fi

    BRANCH_NAME=$(grep "origin" ${GIT_BRANCH} | sed -n ${i}p)

    echo "You will update the branch" ${BRANCH_NAME} 
    git rebase ${BRANCH_NAME}

    for(( i=1; i<=${LINE_NUM}; i++ ));
    do
	MODIFIED_FILE=$(grep "${SEARCH_KEY}" ${GIT_STATUS} | sed -n ${i}p | awk '{print $3}')

	diff ${MODIFIED_FILE} ${MODIFIED_FILE}_bak > /dev/null

	if [ 0 == $? ];
	then
	rm ${MODIFIED_FILE}_old
	rm ${MODIFIED_FILE}_bak
	else
	    diff ${MODIFIED_FILE} ${MODIFIED_FILE}_old
	    if [ 0 == $? ];
	    then
		cp ${MODIFIED_FILE}_bak ${MODIFIED_FILE}

                if [ 0 != $? ];
		then
		    return ${RUN_FAIL};
		fi

		rm ${MODIFIED_FILE}_old 
		rm ${MODIFIED_FILE}_bak
	    else
		echo ${MODIFIED_FILE}
	    fi
	fi
    done

    rm ${GIT_STATUS}
    rm ${GIT_BRANCH}	    
}

function control ()
{
    $1
    
    if [ 0 != $? ];
    then
        echo "run the function $1 faild!"
	exit    
    fi	
}

function main ()
{
    echo "start to search and copy the modified files......"

    control git_status

    echo ""
    echo "---------------------modified files begin-----------------------"

    control find_modified_files
    
    echo "---------------------modified files end-------------------------"
    echo ""

    control git_checkout
    
    control create_temp_files

    control get_branch_num

    control update_code
}

main
