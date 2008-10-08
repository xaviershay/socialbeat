# Counts a very unsteady 120bpm
while(true) do
  `curl -s localhost:2000/beats`
  sleep 0.5
end
