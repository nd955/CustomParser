#!/usr/bin/perl

open (INF, "<", $ARGV[0]) or die "Couldn't open source code.\n";

# these lines of code slurp the whole file into one scalar $input
{
	local $/;
	$input = <INF>;
}

chomp($input);

&lex();
&program();

if($nextToken eq "")
{
	print "Valid Sentence.";
}
else
{
	&error("Invalid Sentence.");
}

sub lex
{
	#terminals
	if($input =~ m/^\s*(program|begin|;|end|:=|read|\(|\)|,|write|if|then|else|while|do|\+|\-|\*|\/|=|<>|<|<=|>=|>)/s)
	{
		$nextToken = $1;
		$input = $';
	}

	#constants
	elsif($input =~ m/^\s*(\d+)/s)
	{
		$nextToken = "CONSTANT";
		$input = $';
	}

	#progname
	elsif($input =~ m/^\s*([A-Z][A-Za-z0-9]*)/s)
	{
		$nextToken = "PROGNAME";
		$input = $';
	}

	#variable
	elsif($input =~ m/^\s*([A-Za-z][A-Za-z0-9]*)/s)
	{
		$nextToken = "VARIABLE";
		$input = $';
	}

	#end
	elsif($input =~ m/^\s*$/s)
	{
		$nextToken = "";
	}

	#error
	else
	{
		&error("$input is invalid.");
	}
}

sub program
{
	if($nextToken eq "program")
	{
		&lex();
		if($nextToken eq "PROGNAME")
		{
			&lex();
			&compoundStmt();
		}
		else
		{
			&error("Expected PROGNAME, saw $nextToken");
		}

		&lex();
	}
	else
	{
		&error("Program does not start with 'program'.");
	}
}
sub compoundStmt
{
	if($nextToken eq "begin")
	{
		&lex();
		&stmt();
		while($nextToken ne "end")
		{
			if($nextToken eq ";")
			{
				&lex();
				&stmt();
			}
			else
			{
				&error("Expected ;, saw $nextToken");
			}
		}
	}
	else
	{
		&error("Expected begin, saw $nextToken");
	}
}
sub stmt
{
	if($nextToken eq "read" | $nextToken eq "write" | $nextToken eq "VARIABLE")
	{
		#don't call lex because we still need nextToken
		#to determine which of these simpleStmt's to use
		&simpleStmt();
	}
	elsif($nextToken eq "begin" | $nextToken eq "if" | $nextToken eq "while")
	{
		#don't call lex because we still need nextToken
		#to determine which of these structuredStmt's to use
		&structuredStmt();
	}
	else
	{
		&error("Expected stmt, saw $nextToken");
	}
}
sub simpleStmt
{
	if($nextToken eq "read")
	{
		&readStmt();
	}
	elsif($nextToken eq "write")
	{
		&writeStmt();
	}
	elsif($nextToken eq "VARIABLE")
	{
		&assignmentStmt();
	}
	else
	{
		&error("Expected simpleStmt, saw $nextToken");
	}
}
sub assignmentStmt
{
	if($nextToken eq "VARIABLE")
	{
		&lex();
		if($nextToken eq ":=")
		{
			&lex();
			&expression();
		}
		else
		{
			&error("Expected :=, saw $nextToken");
		}
	}
	else
	{
		&error("Expected VARIABLE, saw $nextToken");
	}
}
sub readStmt
{
	if($nextToken eq "read")
	{
		&lex();
		if($nextToken eq "(")
		{
			&lex();
			if($nextToken eq "VARIABLE")
			{
				while($nextToken eq "VARIABLE")
				{
					&lex();
					if($nextToken eq ",")
					{
						&lex();
						if($nextToken ne "VARIABLE")
						{
							&error("Expected VARIABLE, saw $nextToken");
						}
					}
					elsif($nextToken eq "VARIABLE")
					{
						&error("Expected ',', saw $nextToken")
					}
				}
			}
			else
			{
				&error("Expected VARIABLE, saw $nextToken");
			}
			if($nextToken eq ")")
			{
				&lex();
			}
			else
			{
				&error("Expected ), saw $nextToken");
			}
		}
		else
		{
			&error("Expected (, saw $nextToken");
		}
	}
	else
	{
		&error("Expected read, saw $nextToken");
	}
}
sub writeStmt
{
	if($nextToken eq "write")
	{
		&lex();
		if($nextToken eq "(")
		{
			&lex();
			&expression();
			while($nextToken eq ",")
			{
				&lex();
				&expression();
			}
			if($nextToken eq ")")
			{
				&lex();
			}
			else
			{
				&error("Expected ), saw $nextToken");
			}
		}
		else
		{
			&error("Expected (, saw $nextToken");
		}
	}
	else
	{
		&error("Expected write, saw $nextToken");
	}
}
sub structuredStmt
{
	if($nextToken eq "begin")
	{
		&compoundStmt();
	}
	elsif($nextToken eq "if")
	{
		&ifStmt();
	}
	elsif($nextToken eq "while")
	{
		&whileStmt();
	}
	else
	{
		&error("Expected structuredStmt, saw $nextToken");
	}
}
sub ifStmt
{
	if($nextToken eq "if")
	{
		&lex();
		&expression();
		if($nextToken eq "then")
		{
			&lex();
			&stmt();
			if($nextToken eq "else")
			{
				&lex();
				&stmt();
			}
		}
		else
		{
			&error("Expected then, saw $nextToken");
		}
	}
	else
	{
		&error("Expected if, saw $nextToken");
	}
}
sub whileStmt
{
	if($nextToken eq "while")
	{
		&lex();
		&expression();
		if($nextToken eq "do")
		{
			&lex();
			&stmt();
		}
		else
		{
			&error("Expected do, saw $nextToken");
		}
	}
	else
	{
		&error("Expected while, saw $nextToken");
	}
}
sub expression
{
	&simpleExpr();
	if($nextToken eq "*" | $nextToken eq "/")
	{
		&multiplyingOperator();
		&simpleExpr();
	}
}
sub simpleExpr
{
	if($nextToken eq "+" | $nextToken eq "-")
	{
		&sign();
	}
	&term();
	while($nextToken eq "+" | $nextToken eq "-")
	{
		&addingOperator();
		&term();
	}
}
sub term
{
	&factor();
	while($nextToken eq "*" | $nextToken eq "/")
	{
		&multiplyingOperator();
		&factor();
	}
}
sub factor
{
	if($nextToken eq "VARIABLE")
	{
		&lex();
	}
	elsif($nextToken eq "CONSTANT")
	{
		&lex();
	}
	elsif($nextToken eq "(")
	{
		&lex();
		&expression();
		if($nextToken eq ")")
		{
			&lex();
		}
		else
		{
			&error("Expected ), saw $nextToken");
		}
	}
	else
	{
		&error("Expected factor, saw $nextToken");
	}
}
sub sign
{
	if($nextToken eq "+" | $nextToken eq "-")
	{
		&lex();
	}
	else
	{
		&error("Expected sign, saw $nextToken");
	}
}
sub addingOperator
{
	if($nextToken eq "+" | $nextToken eq "-")
	{
		&lex();
	}
	else
	{
		&error("Expected addingOperator, saw $nextToken");
	}
}
sub multiplyingOperator
{
	if($nextToken eq "*" | $nextToken eq "/")
	{
		&lex();
	}
	else
	{
		&error("Expected multiplyingOperator, saw $nextToken");
	}
}
sub relationalOperator
{
	if($nextToken eq "=" | $nextToken eq "<>" | $nextToken eq ">" | $nextToken eq "<" | $nextToken eq "<=" | $nextToken eq ">=")
	{
		&lex();
	}
	else
	{
		&error("Expected relationalOperator, saw $nextToken");
	}
}

sub error
{
	die ($_[0]);
}
