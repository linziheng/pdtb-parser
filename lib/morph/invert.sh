#!/bin/csh
#
# Invert flex source of morphological analyser to produce generator.
# Example usage: ./invert.sh gpre gpost < morpha.lex > morphg.lex
#
# John Carroll
# Copyright (c) 2001 University of Sussex
# All rights reserved.

if (! -r $1 || ! -r $2) then
echo "Preamble or postamble file cannot be read"
exit 1
else
endif

cat <<\EOF > /tmp/sh$$
BEGIN{q="\042"; plus="\"+\""; started=0}
/^%%/ {
  if (started==1)
    {print; printf("\n"); system("cat " postfile); exit}
  else {system("cat " prefile); print; started=1}}
/^[ ]*$/ {
  if (started==1) {print}}
/^</ {
  if (!started) {next}
  line=$0; del=""; add=""; affix=""
#
# Extract start condition
#
  if (match(line,/^<[a-z,]+>/)==0)
    {print "Start condition not found" > "/dev/stderr"; exit 1}
  cond=substr(line,RSTART,RLENGTH); line=substr(line,RLENGTH+1)
#
# Extract pattern. Also, if field if of form x{y}, the affix {y}. And
# lookahead /z, if present. Remove any quotes since otherwise can't count
# characters easily. They are restored at end
#
  if (match(line,/[^/ ]+[/ ]/)==0)
    {print "Pattern not found" > "/dev/stderr"; exit 1}
  pattfield=substr(line,RSTART,RLENGTH-1); line=substr(line,RLENGTH)
  gsub(q,"",pattfield)
  if (match(pattfield,/{[^}]+}$/)!=0) # separate off any final {y}
    {pattern=substr(pattfield,1,RSTART-1); affix=substr(pattfield,RSTART)}
  else {pattern=pattfield}
#
  if (match(line,/^[/][^ ]+ /)!=0)
    {la=substr(line,RSTART,RLENGTH-1); line=substr(line,RLENGTH+1)}
  else {la=""}
#
# Extract function call in action, and arguments: del, add, affix in
# that order in all calls. Remove quoting. Function call may not be a
# type we recognise in which case the line gets passed through unchanged
#
  if (match(line,/[(][a-z_]+[(][^)]*[)]/)!=0)
    {fncallfield=substr(line,RSTART+1,RLENGTH-1)
     line=substr(line,RLENGTH+1)}
  else {fncallfield=""}
  if (match(fncallfield,/^[a-z_]+[(]/)!=0)
    {fn=substr(fncallfield,RSTART,RLENGTH-1)}
  else {fn="unknown"}
#
  argsfield=substr(fncallfield,RLENGTH+1,length(fncallfield)-RLENGTH-1)
  gsub(/ /,"",argsfield); gsub(q,"",argsfield)
  nargs=split(argsfield,args,/,/)
  if (nargs>=1) {del=args[1]}
  if (nargs>=2) {add=args[2]}
  if (nargs>=3) {affix=args[3]}
#
# The "en" comment indicates verbs where the past tense and past participle
# form are the same, so an +en suffix can be given to the generator. The
# "disprefer" comment is for an alternative, disprefered form of a word, e.g.
# did/didst; cnull_stem words are irrelevant to generator
#
  if (index(line,"/* en */") && affix=="ed") {suf="e[dn]"} else {suf=affix}
  if (index(line,"/* disprefer */")) {pre="  /* disprefer "; post=" */"}
  else if (fn=="cnull_stem") {pre="  /* cnull "; post=" */"}
  else {pre=""; post=""}
#
# Now build pattern and action, depending on analyser function called
#
# print fn, pattern, del, suf, la, add
#
  if (fn=="stem")
    {patt=substr(pattern,1,length(pattern)-del) add plus suf la
     act=sprintf("gstem(%s,%s)",length(add)+length(affix)+1,q substr(pattern,length(pattern)-del+1) q)}
  else if (fn=="condub_stem")
    {patt=substr(pattern,1,length(pattern)-del) add plus suf la
     sub(/CXY2/,"CXY",patt)
     act=sprintf("gcondub_stem(%s,%s)",length(add)+length(affix)+1,q substr(pattern,length(pattern)-del+1) q)}
  else if (fn=="semi_reg_stem")
    {patt=substr(pattern,1,length(pattern)-del) add plus suf la
     act=sprintf("gsemi_reg_stem(%s,%s)",length(add),q substr(pattern,length(pattern)-del+1,del) q)}
  else if (fn=="cnull_stem")
    {patt=pattern suf la
     act="cnull_stem()"}
  else if (fn=="null_stem")
    {patt=pattern suf "{AFFS}" la
     act="gnull_stem()"}
  else if (fn=="xnull_stem")
    {patt=pattern suf "{SAFFS}" la
     act="gnull_stem()"}
  else if (fn=="ynull_stem")
    {patt=pattern suf "{ALLAFFS}" la
     act="nnull_stem()"}
  else {fn="unknown"}
#
#  print cond, pattfield, fncallfield, argsfield; print patt, act
#
  if (fn=="unknown") {print}
  else
  {gsub(/[.]/,q "." q,patt) # assume any periods are literals
   gsub(q q,"",patt) # delete superfluous adjacent pairs of quotes
   printf("%s%s%s  { return(%s); }%s\n", pre, cond, patt, act, post)}}
\EOF

gawk -f /tmp/sh$$ -v "prefile=$1" -v "postfile=$2"
rm /tmp/sh$$
