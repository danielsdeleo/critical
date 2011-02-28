Monitor(:system) do
  Monitor(hostname) do
    Monitor(:memory) do

      collect_every(10 => :seconds)

      freemem do
        track(:mb_free)
      end
  
    end
  end
end
