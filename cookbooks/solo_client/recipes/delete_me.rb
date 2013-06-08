
Chef::Log.info("Deleting node from the database.")
PersistWrapper.delete
Chef::Log.info("Node is deleted.")

