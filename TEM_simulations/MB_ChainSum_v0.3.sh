##########################
#Building the tree sets for analysing the TEM simulation results
##########################
#SYNTAX :
#sh MB_ChainSum_v0.1.sh <Number of species> <Burnin> <Chain name>
#<Number of species> the number of species per tree
#<Burnin> the proportion of first trees to ignore as a burnin
#<Chain Name> creates a folder named after the chain name to store the results
##########################
#Create .treeset files with all the trees from two mb chains.
#version: 0.3
#Update: Allows a burnin proportion value
#Update: Error in the burnin is now fixed
#----
#guillert(at)tcd.ie - 26/02/2014
##########################


#Set the variables
    #number of species
nsp=$1

    #Burnin
burnin=$2

    #Chain name
name=$3
    
    #header length
header=$nsp
let "header += 5"

    #First tree
FirstTree=$nsp
let "FirstTree += 6"

#Create the folder

mkdir ${name}_treesets

#Create the .treeset file
for f in *.run1.t
    do prefix=$(basename $f .run1.t)

    echo $prefix

    #print the header 
    head -$header ${prefix}.run1.t > ${name}_treesets/${prefix}.treeset

    #Burnin
    BurnTree=$'FirstTree'
    length=$(grep '[&U]' $f | wc -l)
    let "length *= $burnin"
    let "length /= 100"
    let "BurnTree += $length"

    #Add the two list of trees
    sed -n ''"$BurnTree"',$p' ${prefix}.run1.t | sed '$d' >> ${name}_treesets/${prefix}.treeset

    sed -n ''"$BurnTree"',$p' ${prefix}.run2.t >> ${name}_treesets/${prefix}.treeset

done

#end