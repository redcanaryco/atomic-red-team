#****************************************************************************************
#* ADCSV.PL                                                                             *
#*======================================================================================*
#* Author : joe@joeware.net                                                             *
#* Version: V01.00.00                                                                   *
#* Modification History:                                                                *
#*    V01.00.00   2004.12.08  joe    Original Version                                   *
#*--------------------------------------------------------------------------------------*
#* This reads an ADFIND dump and CSVs it.                                               *
#*--------------------------------------------------------------------------------------*
#* Notes:                                                                               *
#****************************************************************************************
#****************************************************************************************


#****************************************************************************************
#* Definitions:                                                                         *
#*--------------------------------------------------------------------------------------*
#*    $TRUE         : Define True for testing.                                          *
#*    $FALSE        : Define False for testing.                                         *
#*    $YES          : Define Yes for testing.                                           *
#*    $NO           : Define No for testing.                                            *
#*    $SCRIPTPATH   : Path to script.                                                   *
#****************************************************************************************
$TRUE=1;
$FALSE=0;
$YES=1;
$NO=0;
($SCRIPTPATH)=($0=~/(^.*)\\.*$/);

$csvdelim=";";
$mvdelim=";";



#
# Display header
#
print "\nADCSV V01.00.00pl  Joe Richards (joe\@joeware.net)  December 2004\n\n";

$update=0;
$help=0;
$infile="";
$outfile="";


map {
     if (/\/infile:(.+)/i) {$infile=$1};
     if (/\/outfile:(.+)/i) {$outfile=$1};
     if (/\/csvdelim:(.+)/i) {$csvdelim=$1};
     if (/\/mvdelim:(.+)/i) {$mvdelim=$1};
     if (/\/(help|h|\?)/i) {$help=1};
    } @ARGV;

if ($help) {DisplayUsage()};
if (!$infile) {DisplayUsage()};

if (!$outfile) {$outfile=$infile.".txt"};

#
#
# Extract attribs and insert into a hash
#
#
$dncnt=0;
$valcnt=0;
%attribs=();
print "Extracting fields from input file $infile...\n";
open IFH,"<$infile" or die("ERR: Couldn't open infile ($infile):$!\n");
foreach $this (<IFH>) 
 {
  $dncnt++ if $this=~/^dn:/;
  next unless $this=~/^>(.+?): /;
  $attribs{$1}=1;
  $valcnt++;
 }

@attriblist=sort keys %attribs;
$attribcnt=@attriblist;
#map {print "$_\n"} @attriblist;

print "DN Count: $dncnt\n";
print "Unique Attribute Count: $attribcnt\n";
print "Values Count: $valcnt\n";


#
#
# Extract objects and slap them into CSV format output
#
#
print "Parsing out objects and writing file $outfile\n";
open OFH,">$outfile"  or die("ERR: Couldn't open outfile ($outfile):$!\n");
OutputHeader(\@attriblist);
$curdn="";
%obj=();
map {$obj{$_}=""} @attriblist;
seek(IFH,0,0);
foreach $this (<IFH>) 
 {
  next unless $this=~/^(dn:|>)/;
  if ($this=~/^dn:(.+)/) 
   {
    print ".";
    $newdn=$1;
    if ($curdn) 
     { # Have an object in storage
      OutputObj($curdn,\%obj);
      %obj=();
      map {$obj{$_}=""} @attriblist;
     }
    $curdn=$newdn;
    next;
   }
  chomp $this;
  ($attrib,$value)=($this=~/^>(.+?): (.+)$/);
  if ($obj{$attrib}=~/\S/) 
   { # multivalue - think quick...
    $obj{$attrib}.=$mvdelim.$value;
   }
  else {$obj{$attrib}=$value};
 }
if ($newdn) {OutputObj($curdn,\%obj)};

close IFH;
close OFH;

print "\n\nThe command completed successfully.\n\n";
exit;


sub OutputHeader
 {
  my $h=shift;
  print OFH "DN".$csvdelim;
  map {print OFH "$_".$csvdelim} @$h;
  print OFH "\n";
 }

sub OutputObj
 {
  my $dn=shift;
  my $a=shift;
  print OFH "\"$dn\"$csvdelim";
  map {print OFH "\"$$a{$_}\"$csvdelim"} sort keys %$a;
  print OFH "\n";
 }


sub DisplayUsage
 {
  print "  Usage: adcsv /infile:input_file [switches]\n\n";
  print "    [switches]\n";
  print "       outfile xxxx    File to output CSV to\n";
  print "       csvdelim x      Delimiter to use for separation of attributes (;)\n";
  print "       mvdelim x       Delimiter to use for separation of MV attribs (;)\n";
  print "\n\n";
  exit;
 }