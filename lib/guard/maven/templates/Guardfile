guard :maven, all_on_start: false, verbose: false do
  watch(%r[src/main/.*/(.*)\.java$]) { |m| "#{m[1]}Test" }
  watch(%r[src/test/.*/(.*)\.java$]) { |m| m[1] }
end
