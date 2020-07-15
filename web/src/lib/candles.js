import * as d3 from 'd3'
import { getWH } from './chart'

export default function candles({ svg, data, x, setCandles }) {
  let { frames } = data

  let lows = frames.map((f) => f.low)
  let highs = frames.map((f) => f.high)
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
    .attr('y', (d) => y(Math.max(d.open, d.close)))
    .attr('width', xBand.bandwidth())
    .attr('height', (d) => (d.open === d.close ? 1 : y(Math.min(d.open, d.close)) - y(Math.max(d.open, d.close))))
    .attr('fill', (d) => (d.open > d.close ? 'red' : 'green'))
    .on('click', (d) => setCandles([d], d3.event.shiftKey))

  let stems = svg
    .selectAll('.stem')
    .data(frames)
    .enter()
    .append('line')
    .attr('class', 'stem')
    .attr('x1', (d) => x(d.index) - xBand.bandwidth() / 2)
    .attr('x2', (d) => x(d.index) - xBand.bandwidth() / 2)
    .attr('y1', (d) => y(d.high))
    .attr('y2', (d) => y(d.low))
    .attr('stroke', (d) => (d.open > d.close ? 'red' : 'green'))

  function zoomed({ t, xz }) {
    candles.attr('x', (f) => xz(f.index) - (xBand.bandwidth() * t.k) / 2).attr('width', xBand.bandwidth() * t.k)
    stems.attr('x1', (f) => xz(f.index) - xBand.bandwidth() / 2 + xBand.bandwidth() * 0.5)
    stems.attr('x2', (f) => xz(f.index) - xBand.bandwidth() / 2 + xBand.bandwidth() * 0.5)
  }

  function zoomend({ frames }) {
    let min = d3.min(frames, (f) => f.low)
    let max = d3.max(frames, (f) => f.high)
    let buffer = (max - min) * 0.05
    y.domain([min - buffer, max + buffer])

    candles
      .transition()
      .duration(200)
      .attr('y', (d) => y(Math.max(d.open, d.close)))
      .attr('height', (d) => (d.open === d.close ? 1 : y(Math.min(d.open, d.close)) - y(Math.max(d.open, d.close))))

    stems
      .transition()
      .duration(200)
      .attr('y1', (d) => y(d.high))
      .attr('y2', (d) => y(d.low))

    gY.call(d3.axisLeft().scale(y))
  }

  return {
    zoomed,
    zoomend,
    getY: () => y,
  }
}
