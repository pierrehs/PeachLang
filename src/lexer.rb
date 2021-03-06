class Lexer
    PEACH_KEYWORDS = ["function", "class", "if", "true", "false", "null", "while"]

    def tokenize(code)
        code.chomp! # Remove extra line breaks
        tokens = []

        current_indent = 0 # number of spaces in the last indent
        indent_stack = []

        i = 0 # Current character position
        while i < code.size
            chunk = code[i..-1]

            if identifier = chunk[/\A([a-z]\w*)/, 1] # Scanning for method & variable names
                if PEACH_KEYWORDS.include?(identifier) # keywords will generate [:IF, "if"]
                    tokens << [identifier.upcase.to_sym, identifier]
                else
                    tokens << [:IDENTIFIER, identifier]
                end
                i += identifier.size # Skip things we just parsed
            elsif constant = chunk[/\A([A-Z]\w*)/, 1] # Scan the constants
                tokens << [:CONSTANT, constant]
                i += constant.size
            elsif number = chunk[/\A([0-9]+)/, 1] # Scan the integers
                tokens << [:NUMBER, number.to_i]
                i += number.size
            elsif string = chunk[/\A"([^"]*)"/, 1] # Scan strings
                tokens << [:STRING, string]
                i += string.size + 2 # Skip twp more chars to exclude the `"` delimeter
            elsif indent = chunk[/\A\:\n( +)/m, 1] # Matches ": <newline> <spaces>"
                if indent.size <= current_indent # Indentation should go up when creating a block
                    raise "Bad indent level, got #{indent.size} indents, " +
                        "expected > #{current_indent}"
                end
                current_indent = indent.size
                indent_stack.push(current_indent)
                tokens << [:INDENT, indent.size]
                i += indent.size + 2
            elsif indent = chunk[/\A\n( *)/m, 1] # Matches "<newline> <spaces>"
                if indent.size == current_indent # Still in the same block since the number of spaces is the same as 'current_indent'
                    tokens << [:NEWLINE, "\n"] # Nothing to do, we're still in the same block
                elsif indent.size < current_indent # Current block is finished because the indent level is lower than current_indent.
                    while indent.size < current_indent
                        indent_stack.pop
                        current_indent = indent_stack.last || 0
                        tokens << [:DEDENT, indent.size]
                    end
                    tokens << [:NEWLINE, "\n"]
                else # indent.size > current_indent, error
                    raise "Missing ':'" #Cannot increase indent level without using ":"
                end
                i += indent.size + 1
            elsif operator = chunk[/\A(\|\||&&|==|!=|<=|>=)/, 1]
                tokens << [operator, operator]
                i += operator.size
            elsif chunk.match(/\A /)
                i += i
            else
                value = chunk[0,1]
                tokens << [value, value]
                i += 1
            end
        end

        while indent = indent_stack.pop
            tokens << [:DEDENT, indent_stack.first || 0]
        end
        tokens
    end
end
