import React from 'react'

export default function CandleDetail({ candle, onClose }) {
  if (!candle) return null

  return (
    <div className="bg-white p-4">
      <div className="absolute top-0 right-0 p-2 cursor-pointer" onClick={onClose}>
        X
      </div>
      <h1>Candle #{candle.index}</h1>
      <table className="text-left">
        <tbody>
          <tr>
            <th>High</th>
            <td>{candle.high}</td>
          </tr>
          <tr>
            <th>Low</th>
            <td>{candle.low}</td>
          </tr>
          <tr>
            <th>Open</th>
            <td>{candle.open}</td>
          </tr>
          <tr>
            <th>Close</th>
            <td>{candle.close}</td>
          </tr>
          <tr>
            <th>Dominion</th>
            <td>bottom: {candle.dominion[0]}</td>
            <td>top: {candle.dominion[1]}</td>
          </tr>
        </tbody>
      </table>
    </div>
  )
}
