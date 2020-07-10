const arrowOffset = 0.2

export default function TrendLineCrosses({ svg, data, x, candles }) {
  let {
    trend_lines: { top, bottom },
  } = data.frames[data.frames.length - 1]

  let lines = top.reduce((acc, v) => [...acc, ...v.lines], [])

  lines = [...lines, ...bottom.reduce((acc, v) => [...acc, ...v.lines], [])]

  let y = candles.getY()
  let crosses = lines.reduce((acc, l) => [...acc, ...l.crosses], [])

  let svgCrosses = svg
    .selectAll('.cross')
    .data(crosses)
    .enter()
    .append('circle')
    .attr('class', 'cross')
    .attr('cx', (c) => x(c.open_coords[0]))
    .attr('cy', (c) => y(c.open_coords[1]))
    .attr('r', 4)
    .attr('fill', 'white')
    .attr('stroke', 'black')

  let arrows = svg
    .selectAll('.arrow')
    .data(crosses)
    .enter()
    .append('text')
    .attr('x', (c) => x(c.open_coords[0] + arrowOffset))
    .attr('y', (c) => y(c.open_coords[1]))
    .attr('dy', '0.35em')
    .text((c) => (c.type === 'reject' || c.type === 'down' ? '↓' : '↑'))

  function zoomed({ xz }) {
    svgCrosses.attr('cx', (c) => xz(c.open_coords[0]))
    arrows.attr('x', (c) => xz(c.open_coords[0] + arrowOffset))
  }

  function zoomend() {
    svgCrosses
      .transition()
      .duration(200)
      .attr('cy', (c) => y(c.open_coords[1]))
    arrows
      .transition()
      .duration(200)
      .attr('y', (c) => y(c.open_coords[1]))
  }

  return { zoomed, zoomend }
}
