class ChangeCalendarEntriesVoteAverageToFloat < ActiveRecord::Migration[8.1]
  def change
    # decimal columns are represented as BigDecimal in Ruby, and
    # BigDecimal#as_json (ActiveSupport's default) renders as a JSON string
    # ("6.5"), not a number. float avoids that at the source for every
    # serializer, present and future, without a per-field cast.
    change_column :calendar_entries, :vote_average, :float
  end
end
