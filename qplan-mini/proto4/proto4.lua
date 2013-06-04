Work = require("work")
Plan = require("plan")

work1 = Work.new("Do work item 1", "Track1", {["Native"] = "L",
                 ["Web"] = "M", ["Server"] = "S", ["BB"] = "S"})
Work.add_work(work1)
work2 = Work.new("Do work item 2", "Track1", {["Native"] = "2L",
                 ["Web"] = "Q", ["Server"] = "S", ["BB"] = "S"})
Work.add_work(work2)

my_plan = Plan.new("MobileQ3", 13, 1, {"2", "1"})

print("Add a new item")
my_plan:add_work_item("Item #3", "Track2")
Work.print_work_items(my_plan:get_ranked_work_items())

print("\nDelete the top item")
my_plan:delete_work_item("2")
Work.print_work_items(my_plan:get_ranked_work_items())

print("\nAdd estimate to work item")
Work.work["3"]:add_estimate("Native", "2L")
Work.work["3"]:add_estimate("Server", "M")
Work.print_work_items(my_plan:get_ranked_work_items())

print("\nAdd more work items")
for i = 4, 10 do
	my_plan:add_work_item("Item #" .. i, "Track2")
end
Work.print_work_items(my_plan:get_ranked_work_items())

print("\nSet cutline")
my_plan:set_cutline(5)
Work.print_work_items(my_plan:get_ranked_work_items())
