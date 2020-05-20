import * as d3 from 'd3'
import _ from 'lodash'
import Momentum from './momentum_line'
import Candles from './candles'

// const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

const margin = { top: 15, right: 50, bottom: 75, left: 50 }
export function getWH() {
  const w = window.innerWidth - margin.left - margin.right
  const h = window.innerHeight - margin.top - margin.bottom
  return { w, h }
}

export function drawChart(frames) {
  let indicators = []

  const { w, h } = getWH()

  const svg = d3
    .select('#container')
    .attr('width', w + margin.left + margin.right)
    .attr('height', h + margin.top + margin.bottom)
    .append('g')
    .attr('transform', `translate(${margin.left},${margin.top})`)

  for (let frame of frames) frame.Date = dateFormat(frame.candle.open_time)
  const dates = frames.map((f) => f.Date)

  const x = d3.scaleLinear().domain([-1, frames.length]).range([0, w])

  var xDateScale = d3.scaleQuantize().domain([0, frames.length]).range(dates)

  var xAxis = d3
    .axisBottom()
    .scale(x)
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

  var chartBody = svg.append('g').attr('class', 'chartBody').attr('clip-path', 'url(#clip)')
  indicators.push(Momentum({ svg: chartBody, frames, x }))
  indicators.push(Candles({ svg: chartBody, frames, x }))

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
    let xz = t.rescaleX(x)

    gX.call(
      d3.axisBottom(xz).tickFormat((d, e, target) => {
        if (d >= 0 && d <= dates.length - 1) {
          d = dates[d]
          let hours = d.getHours()
          let minutes = (d.getMinutes() < 10 ? '0' : '') + d.getMinutes()
          let amPM = hours < 13 ? 'am' : 'pm'
          return `${hours}:${minutes}${amPM} ${d.getDate()}/${d.getMonth() + 1}`
        }
      })
    )

    for (const indicator of indicators) indicator.zoomed({ t, xz })

    // gX.selectAll('.tick text').call(wrap, xBand.bandwidth())
  }

  function zoomend() {
    var t = d3.event.transform
    let xz = t.rescaleX(x)
    clearTimeout(resizeTimer)
    resizeTimer = setTimeout(function () {
      let xmin = new Date(xDateScale(Math.floor(xz.domain()[0])))
      let xmax = new Date(xDateScale(Math.floor(xz.domain()[1])))
      let filtered = _.filter(frames, (d) => d.Date >= xmin && d.Date <= xmax)

      for (const indicator of indicators) indicator.zoomend({ frames: filtered, xz })
    }, 50)
  }
}

const dateFormat = d3.timeParse('%Q')
