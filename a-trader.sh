#!/bin/bash


__ScriptVersion=0.0.1

########################################
#  Insert your appId and appKey below  #
########################################

appId='1234'
appKey='012356789-abcdef-0a1b2c-1b2c3c'

query="gamla%20saker"
categoryId="0"
parallel="8"

#===  FUNCTION  ================================================================
#         NAME:  _get_time
#  DESCRIPTION:  returns the time
#===============================================================================
_get_time() {
    curl -s --header "Content-Type: text/html;charset=UTF-8" \
        "api.tradera.com/v3/PublicService.asmx/GetOfficalTime?appid=$appId&appKey=$appKey"
}

#===  FUNCTION  ================================================================
#         NAME:  _get_CategoryIds
#  DESCRIPTION:  use these to query a certain category
#===============================================================================
_get_CategoryIds() {
    curl -s --header "Content-Type: text/html;charset=UTF-8" \
        "api.tradera.com/v3/publicservice.asmx/GetCategories?appid=$appId&appKey=$appKey" #\
        # awk -vFS='"' -vOFS=' ' '/Category\sId/ {print $2,$4}'
}

#===  FUNCTION  ================================================================
#         NAME:  _search
#  DESCRIPTION:  search tradera for stuff
#===============================================================================
_search() {
    # local query="$@"
    local pageNumber="1"
    local orderBy="Relevance"
    local response pages
    response=$(curl  -s "api.tradera.com/v3/searchservice.asmx/Search?appid=$appId&appKey=$appKey&query=$query&categoryId=$categoryId&pageNumber=$pageNumber&orderBy=$orderBy")
    pages=$(echo $response|grep -oP 'TotalNumberOfPages>\K[^<]+' | tr '\n\r' ' ')
    echo "$response"
    [ "$pages" != "1" ] && \
        seq 2 $pages | xargs -P "$parallel" -n1 -I'{}' \
        curl  -s "api.tradera.com/v3/searchservice.asmx/Search?appid=$appId&appKey=$appKey&query=$query&categoryId=$categoryId&pageNumber="{}"&orderBy=$orderBy"
}


#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
usage ()
{
    echo "Usage :  trader.sh [query] [options] [--]
    Query:
        string to search for
    Options:
    -h|help        Display this message
    -v|version     Display script version
    -l|list-id     List search ids
    -p|parallel    Number of co processes to use
    -t|time        tradera time
    -c|category-id query only for specific id"
}    # ----------  end of function usage  ----------

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------

while getopts ":hvq:p:c:l" opt
do
  case $opt in

    h|help     )  usage; exit 0   ;;

    v|version  )  echo " -- Version $__ScriptVersion"; exit 0   ;;

    # q|query    )  query="${OPTARG//[[:space:]]/%20}";;

    p|parallel )  parallel="$OPTARG";;

    c|category-id     )  categoryId="$OPTARG";;

    l|list-id     )  _get_CategoryIds;;

    t|time     )  _get_time;;

    * )  echo -e "\n  Option does not exist : $OPTARG\n"
          usage; exit 1   ;;

  esac    # --- end of case ---
done
shift $((OPTIND-1))

query="${1//[[:space:]]/%20}"
_search
