import * as d3 from 'd3'
import _ from 'lodash'
import { getWH } from './chart'

export default function candles({ svg, data, x }) {
  let { frames } = data

  let tooltipDiv = d3.select('body').append('div').attr('class', 'tooltip').style('opacity', 0)
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
    .on('mouseover', (d) => candleMouseover(tooltipDiv, d))
    .on('mouseout', (d) => candleMouseout(tooltipDiv, d))

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
    .attr('stroke', (d) => (d.open === d.close ? 'white' : d.open > d.close ? 'red' : 'green'))

  let addReversals = (type) => {
    let _frames = _.filter(frames, (f) => f[`${type}_reversal`])
    return svg
      .selectAll('.reversal-' + type)
      .data(_frames)
      .enter()
      .append('circle')
      .attr('cx', (f) => x(f.index))
      .attr('cy', (f) => {
        return type === 'top' ? y(f.high) - 15 : y(f.low) + 15
      })
      .attr('r', (f) => f[`${type}_reversal`].strength * 0.03 + 1)
  }

  let topReversals = addReversals('top')
  let bottomReversals = addReversals('bottom')

  function zoomed({ t, xz }) {
    candles.attr('x', (f) => xz(f.index) - (xBand.bandwidth() * t.k) / 2).attr('width', xBand.bandwidth() * t.k)
    stems.attr('x1', (f) => xz(f.index) - xBand.bandwidth() / 2 + xBand.bandwidth() * 0.5)
    stems.attr('x2', (f) => xz(f.index) - xBand.bandwidth() / 2 + xBand.bandwidth() * 0.5)
    topReversals.attr('cx', (f) => xz(f.index))
    bottomReversals.attr('cx', (f) => xz(f.index))
  }

  function zoomend({ frames }) {
    let min = d3.min(frames, (f) => f.low)
    let max = d3.max(frames, (f) => f.high)
    let buffer = Math.floor((max - min) * 0.1)
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

    topReversals
      .transition()
      .duration(200)
      .attr('cy', (f) => y(f.high) - 15)
    bottomReversals
      .transition()
      .duration(200)
      .attr('cy', (f) => y(f.low) + 15)

    gY.call(d3.axisLeft().scale(y))
  }

  return {
    zoomed,
    zoomend,
    getY: () => y,
  }
}

function candleMouseover(div, d) {
  div.style('opacity', 1)
  console.log(d)
  div
    .html(
      `
      <ul>
        <li><b>Momentum:</b> ${Math.round(d.momentum * 100) / 100}</li>
        <li><b>High:</b> ${d.high}</li>
        <li><b>Low:</b> ${d.low}</li>
      </ul>
      `
    )
    .style('left', d3.event.pageX + 'px')
    .style('top', d3.event.pageY + 'px')
}

function candleMouseout(div, d) {
  div.style('opacity', 0)
}
