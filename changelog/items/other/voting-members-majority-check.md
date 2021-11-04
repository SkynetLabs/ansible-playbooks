- Added check that we keep majority (> 50%) of MongoDB replicaset voting
  members online before we stop mongo service during deployments, takedowns,
  restarts etc.