import React, { useEffect, useState, useLayoutEffect } from 'react'
import * as chart from './lib/chart'
import { Select } from './UI'

function App() {
  let [data, setData] = useState()
  let [interval, setInterval] = useState('15m')
  let [symbol, setSymbol] = useState('BTCUSDT')

  useEffect(() => {
    fetch(`/prices?symbol=${symbol}&interval=${interval}`)
      .then((r) => r.json())
      .then((data) => {
        setData(data)
        chart.drawChart(data)
      })
  }, [symbol, interval])

  useEffect(() => {
    function resized(e) {
      if (!data) return
      chart.drawChart(data)
    }

    window.addEventListener('resize', resized)
    return () => window.removeEventListener('resize', resized)
  }, [data])

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
        <svg id="chart" />
      </div>
    </>
  )
}

export default App
