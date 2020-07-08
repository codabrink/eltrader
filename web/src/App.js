import React, { useEffect, useState } from 'react'
import * as chart from './lib/chart'
import { Select } from './UI'

function App() {
  let [frames, setFrames] = useState([])
  let [interval, setInterval] = useState("15m")
  let [indicator, setIndicator] = useState("BTCUSDT")

  useEffect(() => {
    fetch(`/prices?interval=${interval}&indicator=${indicator}`)
      .then((r) => r.json())
      .then((frames) => {
        setFrames(frames)
        chart.drawChart(frames)
      })
  }, [interval, indicator])

  return (
    <>
      <div id="control-bar" className="p-3 flex">
        <Select
          label="Indicator"
          options={['BTCUSDT']}
          value={indicator}
          onChange={setIndicator}
        />
        <Select
          label="Interval"
          options={['5m', '15m', '30m', '1h', '4h', '1d']}
          value={interval}
          onChange={setInterval}
        />
      </div>
      <div id="chart-container" className="flex-grow w-full">
        <svg id="chart" key={interval + indicator} />
      </div>
    </>
  )
}

export default App
