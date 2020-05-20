import React from 'react'
import * as d3 from 'd3'
import { getWH } from './chart'

export default function candles({ svg, frames, x }) {
  let tooltipDiv = d3.select('body').append('div').attr('class', 'tooltip').style('opacity', 0)
  let lows = frames.map((f) => f.candle.low)
  let highs = frames.map((f) => f.candle.high)
  let { w, h } = getWH()

  let xBand = d3.scaleBand().domain(d3.range(-1, frames.length)).range([0, w]).padding(0.3)
  let y = d3
    .scaleLinear()
    .domain([d3.min(lows), d3.max(highs)])
    .range([h, 0])
    .nice()
  let yAxis = d3.axisLeft().scale(y)
  var gY = svg.append('g').attr('class', 'axis y-axis').call(yAxis)

  let candles = svg
    .selectAll('.candle')
    .data(frames)
    .enter()
    .append('rect')
    .attr('x', (d, i) => x(i) - xBand.bandwidth())
    .attr('class', 'candle')
    .attr('y', (d) => y(Math.max(d.candle.open, d.candle.close)))
    .attr('width', xBand.bandwidth())
    .attr('height', (d) =>
      d.candle.open === d.candle.close
        ? 1
        : y(Math.min(d.candle.open, d.candle.close)) - y(Math.max(d.candle.open, d.candle.close))
    )
    .attr('fill', (d) => (d.candle.open > d.candle.close ? 'red' : 'green'))
    .on('mouseover', (d) => candleMouseover(tooltipDiv, d))
    .on('mouseout', (d) => candleMouseout(tooltipDiv, d))

  let stems = svg
    .selectAll('.stem')
    .data(frames)
    .enter()
    .append('line')
    .attr('class', 'stem')
    .attr('x1', (d, i) => x(i) - xBand.bandwidth() / 2)
    .attr('x2', (d, i) => x(i) - xBand.bandwidth() / 2)
    .attr('y1', (d) => y(d.candle.high))
    .attr('y2', (d) => y(d.candle.low))
    .attr('stroke', (d) =>
      d.candle.open === d.candle.close ? 'white' : d.candle.open > d.candle.close ? 'red' : 'green'
    )

  function zoomed({ t, xz }) {
    candles.attr('x', (d, i) => xz(i) - (xBand.bandwidth() * t.k) / 2).attr('width', xBand.bandwidth() * t.k)
    stems.attr('x1', (d, i) => xz(i) - xBand.bandwidth() / 2 + xBand.bandwidth() * 0.5)
    stems.attr('x2', (d, i) => xz(i) - xBand.bandwidth() / 2 + xBand.bandwidth() * 0.5)
  }

  function zoomend({ frames }) {
    let min = d3.min(frames, (f) => f.candle.low)
    let max = d3.max(frames, (f) => f.candle.high)
    let buffer = Math.floor((max - min) * 0.1)
    y.domain([min - buffer, max + buffer])

    candles
      .transition()
      .duration(200)
      .attr('y', (d) => y(Math.max(d.candle.open, d.candle.close)))
      .attr('height', (d) =>
        d.candle.open === d.candle.close
          ? 1
          : y(Math.min(d.candle.open, d.candle.close)) - y(Math.max(d.candle.open, d.candle.close))
      )

    stems
      .transition()
      .duration(200)
      .attr('y1', (d) => y(d.candle.high))
      .attr('y2', (d) => y(d.candle.low))

    gY.call(d3.axisLeft().scale(y))
  }

  return {
    zoomed,
    zoomend,
  }
}

function candleMouseover(div, d) {
  div.style('opacity', 1)
  div
    .html(
      `
      <ul>
        <li><b>Momentum:</b> ${Math.round(d.momentum * 100) / 100}</li>
      </ul>
      `
    )
    .style('left', d3.event.pageX + 'px')
    .style('top', d3.event.pageY + 'px')
}

function candleMouseout(div, d) {
  div.style('opacity', 0)
}
