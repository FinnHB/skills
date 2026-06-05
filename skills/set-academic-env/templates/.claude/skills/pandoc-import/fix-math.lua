-- fix-math.lua: tag every Math element with a unique ID for the rescue post-pass
function Math(el)
  el.text = "% TAG:" .. os.time() .. math.random() .. "\n" .. el.text
  return el
end
