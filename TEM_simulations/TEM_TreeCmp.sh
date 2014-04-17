##########################
#Uses TreeCmp java script to compare the distributions of Bayesian trees
##########################
#SYNTAX: TEM_TreeCmp <reference.treeset> <input.treeset> <number of species> <number of random draws> <output>
#with:
#<reference.treeset> a nexus file with the reference trees
#<input.treeset> a nexus file with the trees to compare to the reference tree
#<number of species> number of species per trees
#<number of random draws> number of random draws for the comparison
#<output> a chain name for the output
##########################
#version: 0.5
#Update: improved output format
#Update: correction on the random tree selection from the ref tree: if the ref tree is unique, no sample is performed any more.
#Update: cleaning improved (remove the files from the concern chain only)
#Update: temporary results are now stored in a temporary folder
#----
#guillert(at)tcd.ie - 17/04/2014
##########################
#Requirements:
#-R 3.x
#-TreeCmp java script
#-http://www.la-press.com/treecmp-comparison-of-trees-in-polynomial-time-article-a3300
#-TreeCmp folder to be installed at the level of the analysis
##########################

#!/bin/sh
#INPUT

#Input values
REFtreeset=$1
INPtreeset=$2
species=$3
draws=$4
output=$5

#RANDOM DRAWS LIST

#Creates the temporary output folder
mkdir ${output}_tmp

#Make the nexus file header
header=$species
let "header += 5"
head -$header $REFtreeset > ${output}_tmp/HEADER_${output}.Tree.tmp

#Make the random draws in both list of trees
REFntrees=$(grep 'TREE\|Tree\|tree' $REFtreeset | grep '=\[\|=[[:space:]]\[' | wc -l)
INPntrees=$(grep 'TREE\|Tree\|tree' $INPtreeset | grep '=\[\|=[[:space:]]\[' | wc -l)

#Create the list of trees to sample. If the provided number of random draws is higher than the number of trees, the sample is done with replacement.
echo "if($REFntrees < $draws) {
        REFrep=TRUE } else {
        REFrep=FALSE}
    if($INPntrees < $draws) {
        INPrep=TRUE } else {
        INPrep=FALSE }    
    write(sample(seq(1:$REFntrees), $draws, replace=REFrep), file='REFtreeset.sample', ncolumns=1)
    write(sample(seq(1:$INPntrees), $draws, replace=INPrep), file='INPtreeset.sample', ncolumns=1) " | R --no-save
mv *.sample ${output}_tmp/

#TREE COMPARISONS

#Creates the files of single trees and compare them one to one
for n in $(seq 1 $draws)
do
    #Creates the ref tree file for one draw
    cp ${output}_tmp/HEADER_${output}.Tree.tmp ${output}_tmp/REFtreeset_tree${n}.Tree.tmp
    REFrand=$(sed -n ''"${n}"'p' ${output}_tmp/REFtreeset.sample)
    let "REFrand += $header"
    sed -n ''"$REFrand"'p' $REFtreeset >> ${output}_tmp/REFtreeset_tree${n}.Tree.tmp
    echo 'end;' >> ${output}_tmp/REFtreeset_tree${n}.Tree.tmp

    #Creates the input tree file for one draw
    cp ${output}_tmp/HEADER_${output}.Tree.tmp ${output}_tmp/INPtreeset_tree${n}.Tree.tmp
    INPrand=$(sed -n ''"${n}"'p' ${output}_tmp/INPtreeset.sample)
    let "INPrand += $header"
    sed -n ''"$INPrand"'p' $INPtreeset >> ${output}_tmp/INPtreeset_tree${n}.Tree.tmp
    echo 'end;' >> ${output}_tmp/INPtreeset_tree${n}.Tree.tmp

    #Make the comparison using the TreeCmp java script on all rooted metrics
    java -jar TreeCmp/bin/TreeCmp.jar -r ${output}_tmp/REFtreeset_tree${n}.Tree.tmp -d mc rc ns tt -i  ${output}_tmp/INPtreeset_tree${n}.Tree.tmp -o ${output}_tmp/${output}_draw${n}.Cmp.tmp
done

#SUMMARIZING THE COMPARISONS

#Comparison header
sed -n '1p' ${output}_tmp/${output}_draw1.Cmp.tmp | sed $'s/Tree/Ref.trees\t\Input.trees/g' > ${output}.Cmp

#Add the values from each comparison
for n in $(seq 1 $draws)
do
    REFrand=$(sed -n ''"${n}"'p'  ${output}_tmp/REFtreeset.sample)
    INPrand=$(sed -n ''"${n}"'p'  ${output}_tmp/INPtreeset.sample)
    sed -n '2p' ${output}_tmp/${output}_draw${n}.Cmp.tmp | sed 's/^./'"$REFrand"'@'"$INPrand"'/' | sed $'s/@/\t/' >> ${output}.Cmp
done

#Removing the temporary folder
rm -R ${output}_tmp/

#end