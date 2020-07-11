import React, { useEffect, useState, useCallback } from 'react'
import * as chart from './lib/chart'
import { Select } from './UI'
import queryString from 'query-string'
import CandleDetail from './lib/candle_detail'

function setSearch(search) {
  window.history.replaceState(null, '', `${window.location.pathname}?${queryString.stringify(search)}`)
}

function App() {
  let search = queryString.parse(window.location.search)

  let [candles, setCandles] = useState([])

  let [data, setData] = useState()
  let [interval, setInterval] = useState(search.interval || '15m')
  let [symbol, setSymbol] = useState(search.symbol || 'BTCUSDT')

  let setCandlesCallback = useCallback(
    (_candles, append) => {
      if (append) _candles = [..._candles, ...candles]
      setCandles(_candles)
    },
    [candles]
  )

  let drawChart = (_data) => {
    chart.drawChart({
      data: _data,
      setCandles: setCandlesCallback,
    })
  }

  useEffect(() => {
    fetch(`/prices?symbol=${symbol}&interval=${interval}`)
      .then((r) => r.json())
      .then((data) => {
        setData(data)
        drawChart(data)
      })
  }, [symbol, interval])

  useEffect(() => {
    function resized() {
      if (!data) return
      drawChart(data)
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
          onChange={(symbol) => {
            setSymbol(symbol)
            search.symbol = symbol
            setSearch(search)
          }}
        />
        <Select
          label="Interval"
          options={['5m', '15m', '30m', '1h', '4h', '1d']}
          value={interval}
          onChange={(interval) => {
            setInterval(interval)
            search.interval = interval
            setSearch(search)
          }}
        />
      </div>
      <div id="chart-container" className="flex-grow w-full">
        <svg id="chart" />
      </div>
      <div className="absolute bottom-0 right-0 flex">
        {candles.map((c) => (
          <CandleDetail
            key={c.index}
            candle={c}
            onClose={() => {
              setCandles(candles.filter((cc) => cc != c))
            }}
          />
        ))}
      </div>
    </>
  )
}

export default App
