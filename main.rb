require 'pry'

file = ARGV[0]

file_lines = File.read("./in/#{file}.txt").split("\n")

SCORE_DECLINE_RATE = 1.025

_, _, n_days = file_lines[0].split(' ').map(&:to_i)
book_scores  = file_lines[1].split(' ').map(&:to_i)

libraries = []

# Parse library data
line_index    = 2
library_index = 0
while line_index < file_lines.count
  lib_params = file_lines[line_index].split(' ').map(&:to_i)
  book_ids   = file_lines[line_index + 1].split(' ').map(&:to_i)

  libraries.push({
                     id:              library_index,
                     n_books:         lib_params[0],
                     n_days:          lib_params[1],
                     n_books_per_day: lib_params[2],
                     books:           book_ids.sort_by { |book_id| -book_scores[book_id] }
                 })
  library_index += 1
  line_index    += 2
end

def score_library(library, remaining_days, book_scores)
  curr_day         = library[:n_days]
  total_score      = 0
  scanned_books    = []
  added_book_index = 0
  while curr_day < remaining_days && added_book_index < library[:books].count
    library[:n_books_per_day].times do
      total_score += book_scores[library[:books][added_book_index]]
      scanned_books << library[:books][added_book_index]
      added_book_index += 1
      break if added_book_index >= library[:books].count
    end
    curr_day += 1
  end
  # Take signup days into account
  total_score = total_score / (SCORE_DECLINE_RATE ** library[:n_days])
  {
      total_score:   total_score,
      scanned_books: scanned_books
  }
end

def clear_scanned_books(libraries, scanned_books)
  libraries.each do |lib|
    lib[:books] = lib[:books] - scanned_books
  end
end

signing_up_lib = nil
curr_day       = 0

output = {
    signed_libraries: []
}

while curr_day < n_days
  # Clear the previous signup
  signing_up_lib = nil if signing_up_lib
  # Break the loop if there are no libraries left
  break if libraries.empty?

  scores_cache   = {}
  signing_up_lib = libraries.max_by do |lib|
    # Cache the score data for later usage
    scores_cache[lib[:id]] = score_library(lib, n_days - curr_day, book_scores)
    scores_cache[lib[:id]][:total_score]
  end
  score_data     = scores_cache[signing_up_lib[:id]]
  # If no library can yield more than 0 points, break the loop
  break unless score_data[:total_score] > 0
  output[:signed_libraries] << { library: signing_up_lib, scanned_books: score_data[:scanned_books] }
  # Remove the signed up library
  libraries = libraries - [signing_up_lib]
  # Clean up the scanned books from the remaining libraries
  clear_scanned_books(libraries, score_data[:scanned_books])

  puts "#{file}\t #{curr_day}/#{n_days}"
  # Skip the days needed for the library signup
  curr_day += signing_up_lib[:n_days]
end

submission = [
    output[:signed_libraries].count.to_s,
    *output[:signed_libraries].map do |lib|
      ["#{lib[:library][:id]} #{lib[:scanned_books].count}", lib[:scanned_books].join(' ')].join "\n"
    end
].join "\n"

File.write("./out/#{file}.txt", submission)
