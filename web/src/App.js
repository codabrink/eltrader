import React, { useEffect, useState } from 'react'
import * as chart from './lib/chart'
import { Select } from './UI'

function App() {
  let [frames, setFrames] = useState([])
  let [interval, setInterval] = useState("15m")
  let [symbol, setSymbol] = useState("ADABTC")

  useEffect(() => {
    fetch(`/prices?symbol=${symbol}&interval=${interval}`)
      .then((r) => r.json())
      .then((frames) => {
        setFrames(frames)
        chart.drawChart(frames)
      })
  }, [symbol, interval])

  return (
    <>
      <div id="control-bar" className="p-3 flex">
        <Select
          label="Symbol"
          options={['BTCUSDT', 'ADABTC']}
          value={symbol}
          onChange={setSymbol}
        />
        <Select
          label="Interval"
          options={['5m', '15m', '30m', '1h', '4h', '1d']}
          value={interval}
          onChange={setInterval}
        />
      </div>
      <div id="chart-container" className="flex-grow w-full">
        <svg id="chart" key={interval + symbol} />
      </div>
    </>
  )
}

export default App
