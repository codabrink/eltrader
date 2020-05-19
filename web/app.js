function fetchPrices() {
  fetch('/prices')
    .then((r) => r.json())
    .then(drawChart)
}

let tooltipDiv = d3
  .select('body')
  .append('div')
  .attr('class', 'tooltip')
  .style('opacity', 0)

function drawChart(prices) {
  let momentums = prices.map((p) => p.momentum)
  let lows = prices.map((p) => p.candle.low)
  let highs = prices.map((p) => p.candle.high)

  const months = {
    0: 'Jan',
    1: 'Feb',
    2: 'Mar',
    3: 'Apr',
    4: 'May',
    5: 'Jun',
    6: 'Jul',
    7: 'Aug',
    8: 'Sep',
    9: 'Oct',
    10: 'Nov',
    11: 'Dec',
  }

  var dateFormat = d3.timeParse('%Q')
  for (let price of prices) price.Date = dateFormat(price.candle.open_time)

  const margin = { top: 15, right: 65, bottom: 205, left: 50 },
    w = window.innerWidth - margin.left - margin.right,
    h = window.innerHeight - margin.top - margin.bottom

  var svg = d3
    .select('#container')
    .attr('width', w + margin.left + margin.right)
    .attr('height', h + margin.top + margin.bottom)
    .append('g')
    .attr('transform', `translate(${margin.left},${margin.top})`)

  let dates = _.map(prices, 'Date')

  var xmin = d3.min(prices.map((r) => r.Date.getTime()))
  var xmax = d3.max(prices.map((r) => r.Date.getTime()))
  var xScale = d3.scaleLinear().domain([-1, dates.length]).range([0, w])
  var xDateScale = d3.scaleQuantize().domain([0, dates.length]).range(dates)
  let xBand = d3
    .scaleBand()
    .domain(d3.range(-1, dates.length))
    .range([0, w])
    .padding(0.3)
  var xAxis = d3
    .axisBottom()
    .scale(xScale)
    .tickFormat(function (d, i) {
      d = dates[i]
      hours = d.getHours()
      minutes = (d.getMinutes() < 10 ? '0' : '') + d.getMinutes()
      amPM = hours < 13 ? 'am' : 'pm'
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

  gX.selectAll('.tick text').call(wrap, xBand.bandwidth())

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

  var chartBody = svg
    .append('g')
    .attr('class', 'chartBody')
    .attr('clip-path', 'url(#clip)')

  let momentumLine = chartBody
    .append('path')
    .datum(momentums)
    .attr('class', 'momentum')
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
    .data(prices)
    .enter()
    .append('rect')
    .attr('x', (d, i) => xScale(i) - xBand.bandwidth())
    .attr('class', 'candle')
    .attr('y', (d) => yScale(Math.max(d.candle.open, d.candle.close)))
    .attr('width', xBand.bandwidth())
    .attr('height', (d) =>
      d.candle.open === d.candle.close
        ? 1
        : yScale(Math.min(d.candle.open, d.candle.close)) -
          yScale(Math.max(d.candle.open, d.candle.close))
    )
    .attr('fill', (d) => (d.candle.open > d.candle.close ? 'red' : 'green'))
    .on('mouseover', (d) => candleMouseover(tooltipDiv, d))
    .on('mouseout', (d) => candleMouseout(tooltipDiv, d))

  // draw high and low
  let stems = chartBody
    .selectAll('.stem')
    .data(prices)
    .enter()
    .append('line')
    .attr('class', 'stem')
    .attr('x1', (d, i) => xScale(i) - xBand.bandwidth() / 2)
    .attr('x2', (d, i) => xScale(i) - xBand.bandwidth() / 2)
    .attr('y1', (d) => yScale(d.candle.high))
    .attr('y2', (d) => yScale(d.candle.low))
    .attr('stroke', (d) =>
      d.candle.open === d.candle.close
        ? 'white'
        : d.candle.open > d.candle.close
        ? 'red'
        : 'green'
    )

  svg
    .append('defs')
    .append('clipPath')
    .attr('id', 'clip')
    .append('rect')
    .attr('width', w)
    .attr('height', h)

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
          hours = d.getHours()
          minutes = (d.getMinutes() < 10 ? '0' : '') + d.getMinutes()
          amPM = hours < 13 ? 'am' : 'pm'
          return `${hours}:${minutes}${amPM} ${d.getDate()}/${d.getMonth() + 1}`
        }
      })
    )

    candles
      .attr('x', (d, i) => xScaleZ(i) - (xBand.bandwidth() * t.k) / 2)
      .attr('width', xBand.bandwidth() * t.k)
    stems.attr(
      'x1',
      (d, i) => xScaleZ(i) - xBand.bandwidth() / 2 + xBand.bandwidth() * 0.5
    )
    stems.attr(
      'x2',
      (d, i) => xScaleZ(i) - xBand.bandwidth() / 2 + xBand.bandwidth() * 0.5
    )

    gX.selectAll('.tick text').call(wrap, xBand.bandwidth())
  }

  function zoomend() {
    var t = d3.event.transform
    let xScaleZ = t.rescaleX(xScale)
    clearTimeout(resizeTimer)
    resizeTimer = setTimeout(function () {
      var xmin = new Date(xDateScale(Math.floor(xScaleZ.domain()[0])))
      xmax = new Date(xDateScale(Math.floor(xScaleZ.domain()[1])))
      filtered = _.filter(prices, (d) => d.Date >= xmin && d.Date <= xmax)
      minP = +d3.min(filtered, (d) => d.candle.low)
      maxP = +d3.max(filtered, (d) => d.candle.high)
      buffer = Math.floor((maxP - minP) * 0.1)

      yScale.domain([minP - buffer, maxP + buffer])
      candles
        .transition()
        .duration(200)
        .attr('y', (d) => yScale(Math.max(d.candle.open, d.candle.close)))
        .attr('height', (d) =>
          d.candle.open === d.candle.close
            ? 1
            : yScale(Math.min(d.candle.open, d.candle.close)) -
              yScale(Math.max(d.candle.open, d.candle.close))
        )

      stems
        .transition()
        .duration(200)
        .attr('y1', (d) => yScale(d.candle.high))
        .attr('y2', (d) => yScale(d.candle.low))

      gY.call(d3.axisLeft().scale(yScale))
    }, 50)
  }
}

function wrap(text, width) {
  text.each(function () {
    var text = d3.select(this),
      words = text.text().split(/\s+/).reverse(),
      word,
      line = [],
      lineNumber = 0,
      lineHeight = 1.1,
      y = text.attr('y'),
      dy = parseFloat(text.attr('dy')),
      tspan = text
        .text(null)
        .append('tspan')
        .attr('x', 0)
        .attr('y', y)
        .attr('dy', dy + 'em')
    while ((word = words.pop())) {
      line.push(word)
      tspan.text(line.join(' '))
      if (tspan.node().getComputedTextLength() > width) {
        line.pop()
        tspan.text(line.join(' '))
        line = [word]
        tspan = text
          .append('tspan')
          .attr('x', 0)
          .attr('y', y)
          .attr('dy', ++lineNumber * lineHeight + dy + 'em')
          .text(word)
      }
    }
  })
}

fetchPrices()

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
