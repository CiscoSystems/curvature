class D3.Quota
  w: 100
  h: 100
  r:45
  bkgrnd: "#F2F2F2"
  frgrnd: "#4790B2"

  constructor: (divid) ->
    used = $("#"+divid).dataset.used
    @data = [{"percentage":used},{"percentage":100 - used}]

    @vis = d3.select("#"+divid).append("svg")
      .attr("class","piechart")
      .attr("width", @w)
      .attr("height", @h)
      .style("background-color", "white")
      .append("g")
        .attr("transform", "translate(#{@r + 2},#{@r + 2})")

    @arc = d3.svg.arc()
      .outerRadius(@r)
      .innerRadius(0)

    @pie = d3.layout.pie()
      .sort(null)
      .value((d) -> return d.percentage )
    
    emptyChart()
    animate(@data)
  
  emptyChart: () ->
    piechart = @vis.selectAll(".arc")
      .data(@pie([{"percentage":100}]))
      .enter()
        .append("path")
          .attr("class", "arc")
          .attr("d", @arc)
          .style("fill", @frgrnd)
          .style("stroke", "#CCCCCC")
          .style("stroke-width", 1)
          .each( (d) -> return @current = d )

  animate: (data) ->
    piechart = @vis.selectAll(".arc")
      .data(@pie(data))
      .enter()
        .append("path")
          .attr("class", "arc")
          .attr("d", @arc)
          .style("fill", @frgrnd)
          .style("stroke", "#CCCCCC")
          .style("stroke-width", 1)
          .each( (d) -> return @current = d )
      .transition()
        .duration(500)
        .attrTween("d", (a) ->
          i = d3.interpolate(@current, a)
          @current = i(0)
          return (t) -> return arc(i(t))
        )


