import React, { useEffect, useState } from 'react'
import './App.css'
import * as chart from './lib/chart'

function App() {
  let [frames, setFrames] = useState([])
  useEffect(() => {
    fetch('/prices')
      .then((r) => r.json())
      .then((frames) => {
        setFrames(frames)
        chart.drawChart(frames)
      })
  }, [])

  return (
    <div>
      <svg id="container" />
    </div>
  )
}

export default App
