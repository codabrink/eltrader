import * as d3 from 'd3'
import _ from 'lodash'
import * as momentum from './momentum_line'

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

let tooltipDiv = d3.select('body').append('div').attr('class', 'tooltip').style('opacity', 0)

export function drawChart(frames) {
  let momentums = frames.map((f) => f.momentum)
  let lows = frames.map((f) => f.candle.low)
  let highs = frames.map((f) => f.candle.high)

  const margin = { top: 15, right: 50, bottom: 75, left: 50 }
  const w = window.innerWidth - margin.left - margin.right
  const h = window.innerHeight - margin.top - margin.bottom

  const svg = d3
    .select('#container')
    .attr('width', w + margin.left + margin.right)
    .attr('height', h + margin.top + margin.bottom)
    .append('g')
    .attr('transform', `translate(${margin.left},${margin.top})`)

  for (let frame of frames) frame.Date = dateFormat(frame.candle.open_time)
  const dates = frames.map((f) => f.Date)

  var xmin = d3.min(dates.map((r) => r.getTime()))
  var xmax = d3.max(dates.map((r) => r.getTime()))
  const xScale = d3.scaleLinear().domain([-1, frames.length]).range([0, w])
  var xDateScale = d3.scaleQuantize().domain([0, frames.length]).range(dates)
  let xBand = d3.scaleBand().domain(d3.range(-1, frames.length)).range([0, w]).padding(0.3)
  var xAxis = d3
    .axisBottom()
    .scale(xScale)
    .tickFormat((d, i) => {
      d = dates[i]
      let hours = d.getHours()
      let minutes = (d.getMinutes() < 10 ? '0' : '') + d.getMinutes()
      let amPM = hours < 13 ? 'am' : 'pm'
      return `${hours}:${minutes}${amPM} ${d.getDate()}/${d.getMonth() + 1}`
    })

  svg
    .append('rect')
    .attr('id', 'rect')
    .attr('width', w)
    .attr('height', h)
    .style('fill', 'none')
    .style('pointer-events', 'all')
    .attr('clip-path', 'url(#clip)')

  var gX = svg
    .append('g')
    .attr('class', 'axis x-axis') //Assign "axis" class
    .attr('transform', `translate(0,${h})`)
    .call(xAxis)

  // gX.selectAll('.tick text').call(wrap, xBand.bandwidth())

  let yScale = d3
    .scaleLinear()
    .domain([d3.min(lows), d3.max(highs)])
    .range([h, 0])
    .nice()
  let yAxis = d3.axisLeft().scale(yScale)

  var gY = svg.append('g').attr('class', 'axis y-axis').call(yAxis)
  var y2Scale = d3
    .scaleLinear()
    .domain([d3.min(momentums), d3.max(momentums)])
    .range([h, 0])
    .nice()
  svg.append('g').call(d3.axisRight(y2Scale))

  var chartBody = svg.append('g').attr('class', 'chartBody').attr('clip-path', 'url(#clip)')

  let momentumLine = chartBody.append('g')
  momentumLine
    .append('path')
    .datum(momentums)
    .attr('class', 'line')
    .attr('fill', 'none')
    .attr('stroke', 'steelblue')
    .attr('opacity', 0.5)
    .attr('stroke-width', 1.5)
    .attr(
      'd',
      d3
        .line()
        .x((_, i) => xScale(i))
        .y(y2Scale)
    )

  // draw rectangles
  let candles = chartBody
    .selectAll('.candle')
    .data(frames)
    .enter()
    .append('rect')
    .attr('x', (d, i) => xScale(i) - xBand.bandwidth())
    .attr('class', 'candle')
    .attr('y', (d) => yScale(Math.max(d.candle.open, d.candle.close)))
    .attr('width', xBand.bandwidth())
    .attr('height', (d) =>
      d.candle.open === d.candle.close
        ? 1
        : yScale(Math.min(d.candle.open, d.candle.close)) - yScale(Math.max(d.candle.open, d.candle.close))
    )
    .attr('fill', (d) => (d.candle.open > d.candle.close ? 'red' : 'green'))
    .on('mouseover', (d) => candleMouseover(tooltipDiv, d))
    .on('mouseout', (d) => candleMouseout(tooltipDiv, d))

  // draw high and low
  let stems = chartBody
    .selectAll('.stem')
    .data(frames)
    .enter()
    .append('line')
    .attr('class', 'stem')
    .attr('x1', (d, i) => xScale(i) - xBand.bandwidth() / 2)
    .attr('x2', (d, i) => xScale(i) - xBand.bandwidth() / 2)
    .attr('y1', (d) => yScale(d.candle.high))
    .attr('y2', (d) => yScale(d.candle.low))
    .attr('stroke', (d) =>
      d.candle.open === d.candle.close ? 'white' : d.candle.open > d.candle.close ? 'red' : 'green'
    )

  svg.append('defs').append('clipPath').attr('id', 'clip').append('rect').attr('width', w).attr('height', h)

  const extent = [
    [0, 0],
    [w, h],
  ]

  var resizeTimer
  var zoom = d3
    .zoom()
    .scaleExtent([1, 100])
    .translateExtent(extent)
    .extent(extent)
    .on('zoom', zoomed)
    .on('zoom.end', zoomend)

  svg.call(zoom)

  function zoomed() {
    var t = d3.event.transform
    let xScaleZ = t.rescaleX(xScale)

    gX.call(
      d3.axisBottom(xScaleZ).tickFormat((d, e, target) => {
        if (d >= 0 && d <= dates.length - 1) {
          d = dates[d]
          let hours = d.getHours()
          let minutes = (d.getMinutes() < 10 ? '0' : '') + d.getMinutes()
          let amPM = hours < 13 ? 'am' : 'pm'
          return `${hours}:${minutes}${amPM} ${d.getDate()}/${d.getMonth() + 1}`
        }
      })
    )

    candles.attr('x', (d, i) => xScaleZ(i) - (xBand.bandwidth() * t.k) / 2).attr('width', xBand.bandwidth() * t.k)
    stems.attr('x1', (d, i) => xScaleZ(i) - xBand.bandwidth() / 2 + xBand.bandwidth() * 0.5)
    stems.attr('x2', (d, i) => xScaleZ(i) - xBand.bandwidth() / 2 + xBand.bandwidth() * 0.5)
    momentum.zoomed(momentumLine, xScaleZ, y2Scale)

    // gX.selectAll('.tick text').call(wrap, xBand.bandwidth())
  }

  function zoomend() {
    var t = d3.event.transform
    let xScaleZ = t.rescaleX(xScale)
    clearTimeout(resizeTimer)
    resizeTimer = setTimeout(function () {
      let xmin = new Date(xDateScale(Math.floor(xScaleZ.domain()[0])))
      let xmax = new Date(xDateScale(Math.floor(xScaleZ.domain()[1])))
      let filtered = _.filter(frames, (d) => d.Date >= xmin && d.Date <= xmax)

      let min = d3.min(filtered, (p) => p.candle.low)
      let max = d3.max(filtered, (p) => p.candle.high)
      let buffer = Math.floor((max - min) * 0.1)
      yScale.domain([min - buffer, max + buffer])
      candles
        .transition()
        .duration(200)
        .attr('y', (d) => yScale(Math.max(d.candle.open, d.candle.close)))
        .attr('height', (d) =>
          d.candle.open === d.candle.close
            ? 1
            : yScale(Math.min(d.candle.open, d.candle.close)) - yScale(Math.max(d.candle.open, d.candle.close))
        )

      momentum.zoomend(momentumLine, filtered, xScaleZ, y2Scale)

      stems
        .transition()
        .duration(200)
        .attr('y1', (d) => yScale(d.candle.high))
        .attr('y2', (d) => yScale(d.candle.low))

      gY.call(d3.axisLeft().scale(yScale))
    }, 50)
  }
}

const dateFormat = d3.timeParse('%Q')

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
