guard :maven, all_on_start: true do
  watch(%r[src/main/.*\.java$]) { 'all' }
  watch(%r[src/test/.*/(.*)\.java$]) { |m| m[1] }
  watch(%r[src/.*/resources/.*\.\w+$]) { 'all' }
end
