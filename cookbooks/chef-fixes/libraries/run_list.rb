# Add support for inserting a recipe at a specific location in the runlist.
# This could potentially be dangerous, but it was necessary for my locking
# library. Unsure whether this is still necessary.

class Chef::RunList
  def insert(idx, run_list_item)
    run_list_item = run_list_item.kind_of?(RunListItem) ? run_list_item : parse_entry(run_list_item)
    @run_list_items.insert(idx, run_list_item) unless @run_list_items.include?(run_list_item)
    self
  end
end

