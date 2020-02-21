require 'pry'

file = ARGV[0]

file_lines = File.read("./in/#{file}.txt").split("\n")

n_books, n_libraries, n_days = file_lines[0].split(' ').map(&:to_i)
book_scores                  = file_lines[1].split(' ').map(&:to_i)

libraries = []

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


def score_library(library, remaining_days, without_books, book_scores)
  curr_day         = library[:n_days]
  total_score      = 0
  read_books       = []
  added_book_index = 0
  _books           = library[:books] - without_books
  while curr_day < remaining_days && added_book_index < _books.count
    library[:n_books_per_day].times do
      total_score += book_scores[_books[added_book_index]]
      read_books << _books[added_book_index]
      added_book_index += 1
      break if added_book_index >= _books.count
    end
    curr_day += 1
  end
  {
      total_score: total_score,
      read_books:  read_books
  }
end

read_books       = []
signed_libraries = []
signing_up_lib   = nil
curr_day         = 0

output = {
    signed_libraries: []
}

while curr_day < n_days
  if !signing_up_lib
    if libraries.any?
      signing_up_lib = libraries.max_by { |lib| score_library(lib, n_days - curr_day, read_books, book_scores)[:total_score] }
      score_data = score_library(signing_up_lib, n_days - curr_day, read_books, book_scores)
      break unless score_data[:total_score] > 0
      read_books     = read_books | score_data[:read_books]
      output[:signed_libraries] << { library: signing_up_lib, read_books: score_data[:read_books] }
      libraries               = libraries - [signing_up_lib]
      signing_up_lib[:n_days] -= 1
    end
  else
    signing_up_lib[:n_days] -= 1
    if signing_up_lib[:n_days] <= 0
      signed_libraries = [*signed_libraries, signing_up_lib]
      signing_up_lib   = nil
    end
  end
  puts curr_day
  curr_day += 1
end

submission = [
    output[:signed_libraries].count.to_s,
    *output[:signed_libraries].map do |lib|
      ["#{lib[:library][:id]} #{lib[:read_books].count}", lib[:read_books].join(' ')].join "\n"
    end
].join "\n"

File.write("./out/#{file}.txt", submission)
