# first read arguments to find branch

# create variable for default path

# check if settings has a custom path. if it's "", check default. If there is nothing there, exit script early.

# check to make sure BD installation exists. If there is nothing there, exit script early.

# ORIGINAL LOGIC (approx)

# Check if user has auto start enabled, if so, start discord, otherwise after check/possibly updating, simply exit

# Add settings option for the log? Or simply have it run? Idk what the performance impact of writing logs to file would be, I feel like repeatedly writing lines could definitely be deterimental to performance since it's a disk operation
# Need to look at how logger is working, if it writes each time something is added or if it's a separate task that writes everything once the script ends before I decide