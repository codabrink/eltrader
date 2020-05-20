import * as d3 from 'd3'

export function zoomed(line, x, y) {
  line.select('.line').attr(
    'd',
    d3
      .line()
      .x((_, i) => x(i))
      .y(y)
  )
}

export function zoomend(line, data, x, y) {
  let min = d3.min(data, (d) => d.momentum)
  let max = d3.max(data, (d) => d.momentum)
  y.domain([min, max])

  line
    .select('.line')
    .transition()
    .duration(200)
    .attr(
      'd',
      d3
        .line()
        .x((_, i) => x(i))
        .y(y)
    )
}
