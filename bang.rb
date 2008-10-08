# Bang that drum!
(10*rand).to_i.times do
  `curl -s localhost:2000/bangs`
end
