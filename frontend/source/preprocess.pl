#!/usr/bin/env perl
# Perl program to pre-process C code
# (c) Justin Fletcher
# Version 1.00 (22 Nov 1998)
# Version 1.01 (22 Nov 1998)
#    Added macro variable names
#    Added loop variable assignment
# Version 1.02 (24 Mar 2020)
#    Reused for pre-processing Javascript in JFPatch-as-a-service.
#    Updated to be a little more Perl5-ish.
#    Added support for conditionals.
#
# code to pre-process is of the form :
# #@set <variable> <expression>
#    Changes a variables value
# #@if <expression>
#    Starts a conditional block
# #@else
#    Alternation of the conditional block
# #@endif
#    End of a conditional block
# #@loop [<variable> <expression>]
#    Starts a loop
# #@until <condition>
#    Terminates a loop
# #@macro <name> <number of arguments>|(<argument names>)
#    Starts a multi-line macro
# #@endmacro
#    Ends a multi-line macro
# #@print <expression>
#    Print an expression at run time
# #@<macroname>(<arguments>)
#    Includes a macro
#
# Ourside preprocessor prefix:
# @<expression>@ (anywhere in a line)
#    Evaluates the expression
# @<argnumber>@ (anywhere in a macro line)
#    Evaluates to the argument given
# @<argname>@ (anywhere in a macro line)
#    Evaluates to the argument named
#
# In expressions:
# $<variable>
#    Evaluates to the value of that variable
# $<variable>++
#    Evaluates to the value of that variable, and then increments it
# $<variable>--
#    Evaluates to the value of that variable, and then decrements it
#
# Example 1:
#
# #@set counter 0
# #@loop
# printf("Counter = @$counter@\n");
# #@until $counter++ == 5;
#
# gives:
# printf("Counter = 0\n");
# printf("Counter = 1\n");
# printf("Counter = 2\n");
# printf("Counter = 3\n");
# printf("Counter = 4\n");
# printf("Counter = 5\n");
#
# Example 2:
#
# #@macro TEST 2
# printf("Arg 1 = @1@\n");
# printf("Arg 2 = @2@\n");
# #@endmacro
# #@TEST(hello,there)
#
# gives:
# printf("Arg 1 = hello\n");
# printf("Arg 2 = there\n");
#
# Example 3:
#
# #@macro LOVES (boy,girl)
# printf("@boy@ loves @girl@\n");
# #@endmacro
# #@LOVES(bob,alice)
#
# gives:
# printf("bob loves alice\n");
#

#use warnings;
#use strict;

$infile = '';
$outfile = '';

while (my $arg = shift)
{
    if ($arg =~ /^-(.*)$/)
    {
        my $switch = $1;
        if ($switch =~ /^D(.*?)=(.*)$/)
        {
            Set($1, $2);
        }
        else
        {
            die "Unrecognised switch $arg\n";
        }
    }
    elsif (! $infile)
    {
        $infile = $arg;
    }
    elsif (! $outfile)
    {
        $outfile = $arg;
    }
}
if (($infile eq "") || ($outfile eq ""))
{
  print "Syntax: Preprocess <infile> <outfile>\n";
  exit(1);
}

open(my $ifh, '<', $infile) || die "Failed to open $infile: $!";
open(my $ofh, '>', $outfile) || die "Failed to open $infile: $!";

$readingloop=0;
$loopline="";

$readingmacro=0;
$macroline="";
$macroargs=0;
$macroname="";

@condition_stack = ();
$condition_state = 1;

while (!eof($ifh))
{
  $line=&GetLine($ifh);
  &ProcessLine($line);
}

sub ProcessLine
{
  local ($line)=@_;
  if ($readingloop > 0)
  {
    local($until);
    if ($line !~ /^[ ]*\#\@until/)
    {
      if ($line=~/^[ ]*\#\@loop/)
      { $readingloop++; }
      $loopline.=$line;
    }
    else
    { $readingloop--; $until=$'; chop($until);
      if ($readingloop>0)
      { $loopline.=$line; }
    }
    if ($readingloop==0)
    {
      # printf("loop until $until\n");
      local ($loopl)=$loopline;
      do
      {
        local ($offset)=0;
        while ($offset < length($loopl))
        {
          $line=substr($loopl,$offset,index($loopl,"\n",$offset)-$offset+1);
          # print "Got $line, $offset";
          $offset+=length($line);
          &ProcessLine($line);
        }
      } while (&Evaluate($until)==0);
    }
  }
  elsif ($readingmacro > 0)
  {
    if ($line !~ /^\#\@endmacro/)
    { $macroline.=$line; }
    else
    {
      $readingmacro=0;
      $macros{$macroname}=$macroline;
      $macroargs{$macroname}=$macroargs;
    }
  }
  else
  {
    $line=&Substitute($line);
    if ($line =~ /^[ ]*\#\@([a-zA-Z]*)/)
    {
      local($cmd,$args);
      $cmd=$1; $cmd =~ tr/A-Z/a-z/;
      $args=$';
      $args =~ s/\n//g;
      $args =~ s/^ //g;
      $args =~ s/ $//g;
      # print "Our command $cmd ($args)\n";
      if ($cmd eq 'endif')
      {
        $condition_state = pop @condition_stack;
        if (!defined $condition_state)
        {
            # We reached the top of the condition stack
            $condition_state = 1;
        }
      }
      elsif ($cmd eq 'else')
      {
        # Toggle the state we're in IF we're actually being executed.
        if ($condition_state)
        {
            $condition_state = 0;
        }
        else
        {
            # We can only toggle into the active state if our parent was active.
            if ($#condition_stack == 0)
            {
                # At the top level? That's really an error.
                die "Attempt to use 'else' at the top level";
            }
            else
            {
                my $parent_state = $condition_stack[-1];
                $condition_state = $parent_state;
            }
        }
      }
      elsif ($cmd eq "if")
      {
        push @condition_stack, $condition_state;
        if ($condition_state)
        {
            # Only evaluate if we're currently active
            my $eval = Evaluate($args);
            #print "IF [$args] => $eval\n";
            $condition_state = $eval ? 1 : 0;
        }
      }
      else
      {
        # Obey the condition state
        if ($condition_state)
        {
          if ($cmd eq "set")
          {
            if ($args!~/^([a-zA-Z0-9]+) *(.*)$/)
            { die "Bad set command"; }
            &Set($1,$2);
          }
          elsif ($cmd eq "macro")
          {
            if ($args!~/^([a-zA-Z0-9]+) +([0-9]+)$/)
            {
              if ($args!~/^([a-zA-Z0-9]+) *\((.*\))$/)
              { die "Bad macro command"; }
              $macroname=$1; $macroname=~ tr/A-Z/a-z/;
              $line=$2;
              $macroargs=0;
              while ($line ne "")
              {
                if ($line!~/^([a-zA-Z0-9]+)[,\)]/)
                { die "Bad macro variable name in $line"; }
                $name=$1; $name =~ s/ //;
                $macroargs++;
                $macroargnames{$macroname."_".$macroargs}=$name;
                # print $macroname."_".$macroargs ." = $1\n";
                $line=$';
              }
            }
            else
            {
              $macroname=$1; $macroname=~ tr/A-Z/a-z/;
              $macroargs=$2;
              for ($i=0; $i<$macroargs; $i++)
              { @macroargnames{$macroname."_".$i}=""; }
            }
            $macroline="";
            $readingmacro=1;
          }
          elsif ($cmd eq "print")
          {
            print &Evaluate($args). "\n";
          }
          elsif ($cmd eq "loop")
          {
            if ($args=~/^([a-zA-Z0-9]+) *(.*)$/)
            { &Set($1,$2); }
            $readingloop=1;
            $loopline="";
          }
          else
          {
            if ($args =~ /\((.*)\)/)
            {
              # macro usage
              local($name,$numargs,@argvals,@argnames);
              $args=$1;
              $name=$cmd;
              if (!defined($macros{$name}))
              { die "Unknown macro $name"; }
              $numargs=0;

              while ($args ne "")
              {
                $args=~ s/^ //g;
                if ($args=~/,/) { $left=$`; $right=$'; }
                else { $left=$args; $right=""; }
                $numargs+=1;
                $left=~ s/ $//g;
                $argvals{$numargs}=$left;
                # print "Arg $numargs = $left\n";
                $args=$right;
              }
              if ($numargs != $macroargs{$name})
              {
                die "Macro arguments incorrect for $name ($numargs!=".$macroargs{$name}.")\n";
              }

              # Now run the macro...
              local($macrol)=$macros{$name};
              local ($offset)=0;
              while ($offset < length($macrol))
              {
                $line=substr($macrol,$offset,index($macrol,"\n",$offset)-$offset+1);
                # print "Got $line, $offset";
                $offset+=length($line);
                if ($line=~/@.*@/)
                {
                  while ($line=~/\@([0-9]+)\@/)
                  {
                    $line=$` . $argvals{$1} . $';
                  }
                  while ($line=~/\@([a-zA-Z0-9]+)\@/)
                  {
                    local ($i,$f); $f=-1;
                    for ($i=1; $i<=$numargs; $i++)
                    {
                      $label=$name."_".$i;
                      # print "Find: ".$label . " = ".$macroargnames{$label}."\n";
                      if ($macroargnames{$label} eq $1)
                      { $f=$i; }
                    }
                    if ($f!=-1)
                    { $line=$` . $argvals{$f} . $'; }
                    else
                    { die "Unknown macro variable name $1 in $name"; }
                  }
                }
                &ProcessLine($line);
              }
            }
            else
            {
              die "Unknown command '$cmd'";
            }
          }
        }
      }
    }
    else
    {
      if ($condition_state)
      {
          print $ofh $line;
      }
    }
  }
}

sub GetLine
{
  local ($fh) = @_;
  local ($line);
  if (eof($fh))
  { return ""; }
  $line = <$fh>;
  return $line;
}

sub Substitute
{
  local ($line)=@_;
  local ($left,$right,$match);
  while ($line=~/([^#])\@(.*?)\@/)
  {
    $left=$`.$1; $right=$'; $match=$2;
    $line=$left.&Evaluate($match).$right;
  }
  return $line;
}

sub Evaluate
{
  local ($match) = @_;
  local ($next,$var,$answer);
  # print "Evaluate = $match : ";
  while ($match =~ /\$([a-zA-Z0-9_]+)/)
  {
    $next=$';
    $var= lc $1;
    # print "($var=".$vars{$var}.") ";
    $match=$` . $vars{$var};
    if ($next =~ /^\+\+/) { $vars{$var}++; $next=substr $next,2; }
    if ($next =~ /^--/) { $vars{$var}--; $next=substr $next,2; }
    $match.=$next;
  }
  #print "Resolved as $match\n";
  $answer=eval($match);
  if (!defined($match))
  { die "Evaluation error: $match"; }
  return $answer;
}

sub Set
{
  local($var,$val)=@_;
  $var = lc $var;
  $val =~ s/\\/\\\\/g;
  if ($val=~ s/"/\\"/g)
  { $val="\"$val\""; }
  #print "Setting $var to $val\n";
  $vars{$var} = $val;
}
